#!/bin/bash

# Lightning-safe shutdown script
# Gracefully stops services in correct dependency order
#
# USAGE: ./lightning-shutdown.sh [REASON]
#
# This script ensures your Lightning node shuts down safely by:
# 1. Stopping dependent services first (loopd)
# 2. Giving LND time to flush channel state
# 3. Giving Bitcoin Core time to write UTXO set
#
# Total shutdown time: ~3.5 minutes
#
# INSTALL:
#   sudo cp lightning-shutdown.sh /usr/local/bin/
#   sudo chmod +x /usr/local/bin/lightning-shutdown.sh

set -e

# ============================================================================
# CONFIGURATION - EDIT THESE FOR YOUR SETUP
# ============================================================================

LND_USER="lnduser"                          # User that runs LND
LNCLI_PATH="/home/lnduser/go/bin/lncli"     # Path to lncli binary
BITCOIN_CLI_PATH="/usr/local/bin/bitcoin-cli"  # Path to bitcoin-cli
LOGFILE="/var/log/lightning-shutdown.log"

# Wait times (seconds)
LND_WAIT=60        # Time for LND to flush channel state
BITCOIND_WAIT=120  # Time for Bitcoin Core to write UTXO set
CLEANUP_WAIT=30    # Final cleanup buffer

# ============================================================================
# FUNCTIONS
# ============================================================================

log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | sudo tee -a "$LOGFILE"
}

show_help() {
    cat << EOF
Lightning Network Safe Shutdown Script

USAGE:
    $0 [REASON]

DESCRIPTION:
    Gracefully shuts down Lightning Network services in the correct order:
    1. Loop daemon (if running) - immediate
    2. LND (using lncli stop) - waits ${LND_WAIT}s
    3. Bitcoin Core (using bitcoin-cli stop) - waits ${BITCOIND_WAIT}s
    4. Cleanup remaining services - waits ${CLEANUP_WAIT}s

    Total shutdown time: ~3.5 minutes

OPTIONS:
    --help, -h    Show this help message
    REASON        Optional reason for shutdown (logged)

EXAMPLES:
    $0                           # Manual shutdown
    $0 "UPS power loss"          # UPS-triggered shutdown
    $0 "Maintenance reboot"      # Scheduled maintenance

EXIT CODES:
    0    Success
    1    Error occurred (check logs)

EOF
    exit 0
}

stop_service() {
    local service_name="$1"
    log "Stopping $service_name..."
    if sudo systemctl stop "$service_name" 2>/dev/null; then
        log "$service_name stopped successfully"
        return 0
    else
        log "WARNING: $service_name stop failed or not running"
        return 1
    fi
}

# ============================================================================
# MAIN
# ============================================================================

# Check for help flag
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
fi

main() {
    local reason="${1:-Manual shutdown}"

    log "=========================================="
    log "Lightning graceful shutdown initiated"
    log "Reason: $reason"
    log "=========================================="

    # Step 1: Stop Loop daemon (depends on LND, must stop first)
    log "Step 1/4: Stopping Loop daemon..."
    stop_service loopd || true

    # Step 2: Graceful LND shutdown using lncli
    log "Step 2/4: Initiating graceful LND shutdown..."
    if sudo -u "$LND_USER" "$LNCLI_PATH" stop 2>/dev/null; then
        log "LND shutdown command sent successfully"
    else
        log "WARNING: LND shutdown command failed (may already be stopped)"
    fi

    log "Waiting ${LND_WAIT} seconds for LND to close gracefully..."
    log "(LND is flushing channel state and resolving HTLCs)"
    sleep "$LND_WAIT"

    # Step 3: Graceful Bitcoin Core shutdown
    log "Step 3/4: Initiating graceful Bitcoin Core shutdown..."
    if sudo -u "$LND_USER" "$BITCOIN_CLI_PATH" stop 2>/dev/null; then
        log "Bitcoin Core shutdown command sent successfully"
    else
        log "WARNING: Bitcoin Core shutdown command failed (may already be stopped)"
    fi

    log "Waiting ${BITCOIND_WAIT} seconds for Bitcoin Core to close gracefully..."
    log "(Bitcoin Core is writing UTXO set to disk)"
    sleep "$BITCOIND_WAIT"

    # Step 4: Cleanup - ensure services are stopped via systemd
    log "Step 4/4: Final cleanup..."
    sudo systemctl stop lnd 2>/dev/null || true
    sudo systemctl stop bitcoind 2>/dev/null || true

    log "Waiting ${CLEANUP_WAIT} seconds for final cleanup..."
    sleep "$CLEANUP_WAIT"

    log "=========================================="
    log "Graceful shutdown completed successfully"
    log "Total shutdown time: ~$((LND_WAIT + BITCOIND_WAIT + CLEANUP_WAIT)) seconds"
    log "=========================================="
}

# Ensure log directory and file exist
sudo mkdir -p "$(dirname "$LOGFILE")"
sudo touch "$LOGFILE"

# Run main function with reason parameter
main "$@"

exit 0
