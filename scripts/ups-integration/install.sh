#!/bin/bash

# UPS Integration Installation Script
#
# This script installs and configures UPS monitoring and graceful shutdown
# for a Lightning Network node.
#
# USAGE:
#   sudo ./install.sh
#
# PREREQUISITES:
#   - Ubuntu/Debian system
#   - APC UPS connected via USB
#   - LND and Bitcoin Core already installed and running as systemd services
#
# WHAT THIS SCRIPT DOES:
#   1. Installs apcupsd package
#   2. Deploys configuration files
#   3. Deploys shutdown and backup scripts
#   4. Sets up cron job for channel backups
#   5. Tests UPS communication

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

LND_USER="${LND_USER:-lnduser}"  # User that runs LND (override with env var)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ============================================================================
# COLORS
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================================================
# FUNCTIONS
# ============================================================================

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root (use sudo)"
    fi
}

check_ups() {
    info "Checking for USB UPS..."
    if lsusb | grep -qi "power\|apc\|ups\|cyber"; then
        info "UPS detected via USB"
        lsusb | grep -i "power\|apc\|ups\|cyber" || true
    else
        warn "No USB UPS detected. Make sure your UPS is connected via USB."
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# ============================================================================
# MAIN
# ============================================================================

echo "========================================"
echo "UPS Integration Installer for Lightning"
echo "========================================"
echo

check_root
check_ups

# Step 1: Install apcupsd
info "Installing apcupsd..."
apt-get update -qq
apt-get install -y apcupsd

# Step 2: Backup original config
if [ -f /etc/apcupsd/apcupsd.conf ]; then
    info "Backing up original apcupsd.conf..."
    cp /etc/apcupsd/apcupsd.conf /etc/apcupsd/apcupsd.conf.backup.$(date +%Y%m%d)
fi

# Step 3: Deploy configuration
info "Deploying apcupsd configuration..."
cp "$SCRIPT_DIR/apcupsd.conf" /etc/apcupsd/apcupsd.conf

# Step 4: Deploy hook script
info "Deploying UPS event hook script..."
cp "$SCRIPT_DIR/apccontrol.local" /etc/apcupsd/apccontrol.local
chmod +x /etc/apcupsd/apccontrol.local

# Step 5: Deploy shutdown script
info "Deploying Lightning shutdown script..."
cp "$SCRIPT_DIR/lightning-shutdown.sh" /usr/local/bin/lightning-shutdown.sh
chmod +x /usr/local/bin/lightning-shutdown.sh

# Update shutdown script with correct user
sed -i "s/LND_USER=\"lnduser\"/LND_USER=\"$LND_USER\"/" /usr/local/bin/lightning-shutdown.sh

# Step 6: Deploy backup script
info "Deploying channel backup script..."
BACKUP_SCRIPT_DIR="/home/$LND_USER/scripts"
mkdir -p "$BACKUP_SCRIPT_DIR"
cp "$SCRIPT_DIR/backup_scb.sh" "$BACKUP_SCRIPT_DIR/backup_scb.sh"
chmod +x "$BACKUP_SCRIPT_DIR/backup_scb.sh"
chown -R "$LND_USER:$LND_USER" "$BACKUP_SCRIPT_DIR"

# Create backup directory
mkdir -p "/home/$LND_USER/backups/lnd"
chown -R "$LND_USER:$LND_USER" "/home/$LND_USER/backups"

# Step 7: Set up cron job for backups
info "Setting up cron job for channel backups (every 5 minutes)..."
CRON_LINE="*/5 * * * * $BACKUP_SCRIPT_DIR/backup_scb.sh"
(crontab -u "$LND_USER" -l 2>/dev/null | grep -v "backup_scb.sh"; echo "$CRON_LINE") | crontab -u "$LND_USER" -

# Step 8: Enable apcupsd
info "Enabling apcupsd service..."
sed -i 's/ISCONFIGURED=no/ISCONFIGURED=yes/' /etc/default/apcupsd

# Step 9: Start apcupsd
info "Starting apcupsd..."
systemctl restart apcupsd
systemctl enable apcupsd

# Wait for daemon to initialize
sleep 3

# Step 10: Test UPS communication
echo
echo "========================================"
echo "Testing UPS Communication"
echo "========================================"
if apcaccess status 2>/dev/null | grep -q "STATUS"; then
    info "UPS communication successful!"
    echo
    apcaccess status | head -20
else
    warn "Could not communicate with UPS. Check USB connection."
fi

echo
echo "========================================"
echo "Installation Complete!"
echo "========================================"
echo
info "Files installed:"
echo "  - /etc/apcupsd/apcupsd.conf (UPS configuration)"
echo "  - /etc/apcupsd/apccontrol.local (event hooks)"
echo "  - /usr/local/bin/lightning-shutdown.sh (shutdown script)"
echo "  - $BACKUP_SCRIPT_DIR/backup_scb.sh (channel backups)"
echo
info "Cron job added for user $LND_USER:"
echo "  - Channel backup every 5 minutes"
echo
info "Commands to verify:"
echo "  - apcaccess status           # Check UPS status"
echo "  - systemctl status apcupsd   # Check daemon status"
echo "  - tail -f /var/log/apcupsd.events  # Watch power events"
echo
warn "IMPORTANT: Configure your BIOS for 'Power On after AC Loss'"
warn "IMPORTANT: Test the full shutdown sequence before relying on it!"
echo
