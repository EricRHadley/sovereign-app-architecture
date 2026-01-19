#!/bin/bash

# Lightning Channel Backup Script (SCB - Static Channel Backup)
#
# This script backs up your LND channel.backup file to multiple locations.
# The channel.backup is CRITICAL - it's the only way to recover funds
# if your node dies and you need to force-close channels.
#
# USAGE:
#   ./backup_scb.sh           # Manual backup
#   crontab: */5 * * * * /home/lnduser/scripts/backup_scb.sh
#
# INSTALL:
#   1. Copy to your scripts directory
#   2. chmod +x backup_scb.sh
#   3. Add to crontab (every 5 minutes recommended)
#
# NOTE: This is SEPARATE from graceful shutdown. Backups run continuously.

set -e

# ============================================================================
# CONFIGURATION - EDIT THESE FOR YOUR SETUP
# ============================================================================

# Path to LND's channel.backup file
SCB_PATH="$HOME/.lnd/data/chain/bitcoin/mainnet/channel.backup"

# Local backup directory
BACKUP_DIR="$HOME/backups/lnd"

# Log file
LOGFILE="$BACKUP_DIR/backup.log"

# How many days of backups to keep locally
RETENTION_DAYS=30

# Remote backup (optional) - uncomment and configure
# REMOTE_USER="lnduser"
# REMOTE_HOST="backup-server.example.com"
# REMOTE_PORT="22"
# REMOTE_PATH="/home/lnduser/lnd_backups/channel.backup.latest"

# ============================================================================
# FUNCTIONS
# ============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

# ============================================================================
# MAIN
# ============================================================================

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Ensure log file exists
touch "$LOGFILE"

# Generate timestamp for this backup
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Check if channel.backup exists
if [ ! -f "$SCB_PATH" ]; then
    log "ERROR: channel.backup not found at $SCB_PATH"
    log "Is LND running? Has it created any channels?"
    exit 1
fi

# Get file info for logging
FILE_SIZE=$(ls -lh "$SCB_PATH" | awk '{print $5}')
FILE_HASH=$(sha256sum "$SCB_PATH" | cut -d' ' -f1 | head -c 16)

log "INFO: Starting backup (size: $FILE_SIZE, hash: ${FILE_HASH}...)"

# Create timestamped local backup
if cp "$SCB_PATH" "$BACKUP_DIR/channel.backup.$TIMESTAMP"; then
    log "SUCCESS: Local backup created: channel.backup.$TIMESTAMP"
else
    log "ERROR: Failed to create local backup"
    exit 1
fi

# Create/update "latest" copy for easy access
cp "$SCB_PATH" "$BACKUP_DIR/channel.backup.latest"

# Clean up old backups (keep RETENTION_DAYS days)
DELETED_COUNT=$(find "$BACKUP_DIR" -name "channel.backup.[0-9]*" -mtime +$RETENTION_DAYS -delete -print | wc -l)
if [ "$DELETED_COUNT" -gt 0 ]; then
    log "INFO: Cleaned up $DELETED_COUNT backups older than $RETENTION_DAYS days"
fi

# Remote backup (if configured)
if [ -n "${REMOTE_HOST:-}" ]; then
    if rsync -q -e "ssh -p ${REMOTE_PORT:-22}" "$SCB_PATH" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}" 2>/dev/null; then
        log "SUCCESS: Backup copied to remote: $REMOTE_HOST"
    else
        log "WARNING: Failed to copy to remote (may be offline)"
    fi
fi

# Count total backups
BACKUP_COUNT=$(find "$BACKUP_DIR" -name "channel.backup.*" 2>/dev/null | wc -l)
log "INFO: Backup complete. Total local backups: $BACKUP_COUNT"

exit 0
