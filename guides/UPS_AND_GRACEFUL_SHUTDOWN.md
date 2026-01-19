# UPS Integration & Graceful Shutdown

How to protect your Lightning node from power failures with automatic graceful shutdown and recovery.

---

## Why This Matters

A Lightning node manages real money in payment channels. Improper shutdown can cause:

- **Force-closed channels**: Peers may close channels if your node appears unresponsive
- **Lost HTLCs**: In-flight payments may fail or get stuck
- **Database corruption**: LND's channel.db can corrupt if not closed cleanly
- **Lost funds**: In extreme cases, corrupted state can mean lost sats

A proper shutdown sequence ensures:
- All pending HTLCs are resolved or safely stored
- Channel state is flushed to disk
- Bitcoin Core's UTXO set is written cleanly
- Services stop in the correct dependency order

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    POWER PROTECTION ARCHITECTURE                         │
└─────────────────────────────────────────────────────────────────────────┘

  WALL POWER ─────────────────────────────────────────────────────────────
       │
       ▼
  ┌─────────────┐     USB status
  │     UPS     │─────────────────┐
  │ (Battery)   │                 │
  └──────┬──────┘                 │
         │                        ▼
         │ AC Output      ┌─────────────────┐
         │                │    apcupsd      │  Monitors battery level
         │                │    daemon       │  Triggers shutdown at threshold
         ▼                └────────┬────────┘
  ┌─────────────┐                  │
  │   SERVER    │                  │ Calls on critical battery
  │             │                  ▼
  │ ┌─────────┐ │          ┌─────────────────┐
  │ │bitcoind │ │          │ lightning-      │
  │ └────┬────┘ │          │ shutdown.sh     │
  │      │      │          │ (~3.5 minutes)  │
  │      ▼      │          └─────────────────┘
  │ ┌─────────┐ │
  │ │   lnd   │ │◀─────── Channel backups every 5 min (separate from shutdown)
  │ └────┬────┘ │
  │      │      │
  │      ▼      │          BIOS Settings:
  │ ┌─────────┐ │          - Auto power-on after AC loss
  │ │  loopd  │ │          - Wake-on-LAN enabled
  │ └─────────┘ │
  └─────────────┘
```

---

## Hardware Requirements

### UPS (Uninterruptible Power Supply)

| Specification | Recommended | Why |
|---------------|-------------|-----|
| Capacity | 1000VA+ (600W+) | Server + monitor runtime |
| Runtime | 10+ minutes at load | Time for graceful shutdown |
| Interface | USB | For status monitoring |
| Waveform | Pure sine wave | Server-grade PSUs need clean power |

**Recommended models:**
- APC Smart-UPS SMC1500C (what we use)
- CyberPower PR1500LCD
- APC Back-UPS Pro

### Server BIOS Requirements

Your server motherboard must support:
- **"Restore on AC Power Loss"** - Auto-boot when power returns
- **Wake-on-LAN** - Remote power-on via network (optional but recommended)

Most server boards (Dell, HP, Supermicro, Intel) have these. Consumer boards vary.

---

## Software Components

### 1. apcupsd - UPS Monitoring Daemon

Monitors UPS via USB and triggers actions on power events.

```bash
# Install on Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y apcupsd
```

### 2. Custom Shutdown Script

Stops services in correct order with proper wait times.

### 3. Systemd Service Files

Ensures services start in correct order on boot and stop gracefully.

---

## Shutdown Sequence

The correct order is critical. Services that depend on others must stop first.

```
┌─────────────────────────────────────────────────────────────────┐
│                    GRACEFUL SHUTDOWN SEQUENCE                    │
│                    Total Time: ~3.5 minutes                      │
└─────────────────────────────────────────────────────────────────┘

     ┌──────────────┐
     │  TRIGGER     │  Manual: lightning-shutdown.sh
     │              │  UPS: apccontrol.local hook
     └──────┬───────┘  Systemd: shutdown.target
            │
            ▼
     ┌──────────────┐
     │ 1. LOOPD     │  Stop Loop daemon (submarine swaps)
     │   (immediate)│  Depends on LND, must stop first
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │ 2. LND       │  lncli stop
     │  (60 seconds)│  Flushes channel state, resolves HTLCs
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │ 3. BITCOIND  │  bitcoin-cli stop
     │ (120 seconds)│  Writes UTXO set to disk (can be large)
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │ 4. CLEANUP   │  Final systemctl stop commands
     │  (30 seconds)│  Ensure all processes terminated
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │  SAFE TO     │
     │  POWER OFF   │
     └──────────────┘
```

**Why these wait times?**
- **LND (60s)**: Needs to commit pending HTLCs and flush channel.db
- **Bitcoin Core (120s)**: UTXO set can be several GB and must be written atomically
- **Cleanup (30s)**: Buffer for any stragglers

---

## Startup Sequence

On power restoration, services must start in reverse dependency order.

```
┌─────────────────────────────────────────────────────────────────┐
│                    BOOT / STARTUP SEQUENCE                       │
└─────────────────────────────────────────────────────────────────┘

  Power Restored
        │
        ▼
  ┌─────────────────┐
  │  BIOS           │  "Restore on AC Power Loss" = ON
  │  Auto Power-On  │  Server boots automatically
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ 1. network      │  systemd network target
  │    .target      │
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ 2. bitcoind     │  After=network.target
  │    .service     │  Loads UTXO set, syncs blocks
  └────────┬────────┘
           │
           ▼
  ┌─────────────────┐
  │ 3. lnd.service  │  After=bitcoind.service
  │                 │  Requires=bitcoind.service
  └────────┬────────┘
           │
           ├────────────────────┬─────────────────┐
           ▼                    ▼                 ▼
  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
  │ 4. lnd-unlock   │  │ 4. loopd        │  │ 4. tunnel       │
  │    .service     │  │    .service     │  │    .service     │
  │  (auto-unlock)  │  │  (liquidity)    │  │  (remote access)│
  └─────────────────┘  └─────────────────┘  └─────────────────┘
           │
           ▼
  ┌─────────────────┐
  │  NODE ONLINE    │  Fully autonomous - no manual intervention
  └─────────────────┘
```

---

## Power Event Flow

### Power Failure

```
Wall power lost
      │
      ▼
UPS battery takes over (instant)
      │
      ▼
apcupsd detects "onbattery" event
      │
      ├──► Logs to /var/log/ups-events.log
      │
      └──► Disables new logins (optional)
      │
      ▼
apcupsd monitors battery level
      │
      ├─── Battery > 20% AND Runtime > 10 min ───► Continue running
      │
      └─── Battery ≤ 20% OR Runtime ≤ 10 min ───► TRIGGER SHUTDOWN
                                                        │
                                                        ▼
                                              lightning-shutdown.sh
                                                  "UPS Battery Critical"
                                                        │
                                                        ▼
                                                 [3.5 min shutdown]
                                                        │
                                                        ▼
                                                  Server powers off
```

### Power Restoration

```
Wall power restored
      │
      ├─── Server was OFF ───► BIOS auto-powers on
      │                              │
      │                              ▼
      │                        systemd boot sequence
      │                              │
      │                              ▼
      │                        Services start in order
      │
      └─── Server was ON ────► apcupsd detects "offbattery"
           (power returned              │
            before shutdown)            ▼
                               Logs "Power restored"
                               Re-enables logins
                               Continues normal operation
```

---

## Installation Guide

### Step 1: Configure BIOS Settings

Enter your server's BIOS/UEFI setup (usually F2, F10, or Del during boot).

**Required settings:**
```
Power Management:
  └── After Power Loss: [Power On]  (may be called "Restore on AC Loss")

Advanced → Network:
  └── Wake-on-LAN: [Enabled]
```

Save and exit BIOS.

### Step 2: Install apcupsd

```bash
# Install the daemon
sudo apt-get update
sudo apt-get install -y apcupsd

# Verify UPS is detected
lsusb | grep -i ups
# Should show something like: American Power Conversion
```

### Step 3: Configure apcupsd

Create `/etc/apcupsd/apcupsd.conf`:

```bash
sudo tee /etc/apcupsd/apcupsd.conf > /dev/null << 'EOF'
## apcupsd.conf for USB-connected UPS

# UPS name (customize this)
UPSNAME MyUPS

# Cable and type for USB UPS
UPSCABLE usb
UPSTYPE usb

# Device - leave blank for USB auto-detection
DEVICE

# Network server (for monitoring tools)
NETSERVER on
NISIP 127.0.0.1
NISPORT 3551

# Timing parameters - CRITICAL SETTINGS
ONBATTERYDELAY 6      # Seconds before "on battery" event fires
BATTERYLEVEL 20       # Shutdown when battery level drops to this %
MINUTES 10            # Shutdown when this many minutes of runtime remain
TIMEOUT 0             # Disable timeout-based shutdown (we use level/minutes)

# Shutdown behavior
ANNOY 300             # Warn users every 5 minutes when on battery
ANNOYDELAY 60         # Initial delay before warnings
KILLDELAY 0           # Don't kill UPS power (let it manage itself)

# Logging
EVENTSFILE /var/log/apcupsd.events
STATFILE /var/log/apcupsd.status

# Power failure behavior
NOLOGON disable       # Disable logins when on battery
EOF
```

### Step 4: Create the Shutdown Script

Create `/usr/local/bin/lightning-shutdown.sh`:

```bash
sudo tee /usr/local/bin/lightning-shutdown.sh > /dev/null << 'SCRIPT'
#!/bin/bash

# Lightning-safe shutdown script
# Gracefully stops services in correct dependency order

LOGFILE="/var/log/lightning-shutdown.log"
LND_USER="lnduser"  # Change to your LND user

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | sudo tee -a "$LOGFILE"
}

# Help
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat << EOF
Lightning Network Safe Shutdown Script

USAGE: $0 [REASON]

Gracefully shuts down services in order:
1. Loop daemon (immediate)
2. LND (60 seconds for channel flush)
3. Bitcoin Core (120 seconds for UTXO write)
4. Cleanup (30 seconds)

Total time: ~3.5 minutes
EOF
    exit 0
fi

main() {
    log "=== Lightning graceful shutdown initiated ==="
    log "Reason: ${1:-Manual shutdown}"

    # 1. Stop Loop daemon (depends on LND)
    log "Stopping Loop daemon..."
    if sudo systemctl stop loopd 2>/dev/null; then
        log "Loop daemon stopped"
    else
        log "Loop daemon not running or stop failed"
    fi

    # 2. Graceful LND shutdown
    log "Stopping LND (60 second wait)..."
    if sudo -u "$LND_USER" lncli stop 2>/dev/null; then
        log "LND stop command sent"
    else
        log "LND stop command failed (may already be stopped)"
    fi
    sleep 60

    # 3. Graceful Bitcoin Core shutdown
    log "Stopping Bitcoin Core (120 second wait)..."
    if sudo -u "$LND_USER" bitcoin-cli stop 2>/dev/null; then
        log "Bitcoin Core stop command sent"
    else
        log "Bitcoin Core stop command failed (may already be stopped)"
    fi
    sleep 120

    # 4. Cleanup - ensure services are stopped
    log "Final cleanup..."
    sudo systemctl stop lnd 2>/dev/null || true
    sudo systemctl stop bitcoind 2>/dev/null || true
    sleep 30

    log "=== Graceful shutdown completed ==="
    log "Total time: ~3.5 minutes"
}

# Ensure log file exists
sudo mkdir -p "$(dirname "$LOGFILE")"
sudo touch "$LOGFILE"

main "$@"
SCRIPT

# Make executable
sudo chmod +x /usr/local/bin/lightning-shutdown.sh
```

### Step 5: Create UPS Hook Script

Create `/etc/apcupsd/apccontrol.local`:

```bash
sudo tee /etc/apcupsd/apccontrol.local > /dev/null << 'HOOK'
#!/bin/bash
# Custom UPS event hooks for Lightning node
# Called by apcupsd on power events

LOGFILE="/var/log/ups-events.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

case "$1" in
    doshutdown)
        # Critical battery - initiate graceful shutdown
        log "CRITICAL: Battery critical, initiating Lightning-safe shutdown"
        /usr/local/bin/lightning-shutdown.sh "UPS Battery Critical"
        ;;
    powerout)
        log "ALERT: Power failure detected"
        ;;
    onbattery)
        log "WARNING: Running on battery power"
        ;;
    offbattery)
        log "INFO: Power restored, back on mains"
        ;;
    mainsback)
        log "INFO: Mains power has returned"
        ;;
    failing)
        log "CRITICAL: UPS battery is failing"
        ;;
    timeout)
        log "ALERT: UPS timeout reached"
        ;;
    loadlimit)
        log "WARNING: UPS load limit reached"
        ;;
    runlimit)
        log "WARNING: UPS runtime limit reached"
        ;;
    *)
        log "EVENT: $1"
        ;;
esac

exit 0
HOOK

sudo chmod +x /etc/apcupsd/apccontrol.local
```

### Step 6: Enable apcupsd

```bash
# Enable in defaults
sudo sed -i 's/ISCONFIGURED=no/ISCONFIGURED=yes/' /etc/default/apcupsd

# Start and enable service
sudo systemctl restart apcupsd
sudo systemctl enable apcupsd

# Verify it's working
apcaccess status
```

You should see output like:
```
APC      : 001,036,0856
DATE     : 2025-09-23 14:30:00 -0400
HOSTNAME : lightning-node
MODEL    : Smart-UPS C 1500
STATUS   : ONLINE
LINEV    : 120.0 Volts
LOADPCT  : 12.0 Percent
BCHARGE  : 100.0 Percent
TIMELEFT : 89.0 Minutes
```

---

## Systemd Service Files

### bitcoind.service

```ini
[Unit]
Description=Bitcoin Core Daemon
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/bitcoind -daemon=0
ExecStop=/usr/local/bin/bitcoin-cli stop

User=lnduser
Group=lnduser

Restart=on-failure
RestartSec=30
TimeoutStopSec=120

# Graceful shutdown
KillMode=mixed
KillSignal=SIGTERM
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
```

### lnd.service

```ini
[Unit]
Description=Lightning Network Daemon
After=network.target bitcoind.service
Requires=bitcoind.service

[Service]
Type=simple
ExecStart=/home/lnduser/go/bin/lnd
ExecStop=/home/lnduser/go/bin/lncli stop

User=lnduser
Group=lnduser

Restart=on-failure
RestartSec=30
TimeoutStopSec=120

# Graceful shutdown - CRITICAL
KillMode=mixed
KillSignal=SIGTERM
SendSIGKILL=no

Environment="HOME=/home/lnduser"

[Install]
WantedBy=multi-user.target
```

### loopd.service

```ini
[Unit]
Description=Lightning Loop Daemon
After=lnd.service
BindsTo=lnd.service

[Service]
Type=simple
ExecStart=/home/lnduser/go/bin/loopd

User=lnduser
Group=lnduser

Restart=on-failure
RestartSec=30
TimeoutStopSec=60

[Install]
WantedBy=multi-user.target
```

### lnd-unlock.service (Auto-unlock wallet on boot)

```ini
[Unit]
Description=LND Wallet Auto-Unlock
After=lnd.service
Requires=lnd.service

[Service]
Type=oneshot
ExecStart=/home/lnduser/scripts/lnd-unlock.sh
RemainAfterExit=yes

User=lnduser
Group=lnduser

[Install]
WantedBy=multi-user.target
```

---

## Channel Backup (Separate from Shutdown)

Channel backups run continuously via cron, not during shutdown.

### backup_scb.sh

```bash
#!/bin/bash
# Lightning Channel Backup Script
# Run via cron every 5 minutes

SCB_PATH="$HOME/.lnd/data/chain/bitcoin/mainnet/channel.backup"
BACKUP_DIR="$HOME/backups/lnd"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGFILE="$BACKUP_DIR/backup.log"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

# Check if channel.backup exists
if [ ! -f "$SCB_PATH" ]; then
    log "ERROR: channel.backup not found at $SCB_PATH"
    exit 1
fi

# Create timestamped backup
cp "$SCB_PATH" "$BACKUP_DIR/channel.backup.$TIMESTAMP"
log "SUCCESS: Local backup created: channel.backup.$TIMESTAMP"

# Keep latest copy for easy access
cp "$SCB_PATH" "$BACKUP_DIR/channel.backup.latest"

# Clean up old backups (keep 30 days)
find "$BACKUP_DIR" -name "channel.backup.*" -mtime +30 -delete
log "INFO: Cleaned up backups older than 30 days"

# Optional: Copy to remote server
# rsync -q "$SCB_PATH" user@remote:/backups/channel.backup.latest 2>/dev/null
```

### Cron Setup

```bash
# Edit crontab
crontab -e

# Add this line (runs every 5 minutes)
*/5 * * * * /home/lnduser/scripts/backup_scb.sh
```

---

## Testing

### Test UPS Communication

```bash
# Check UPS status
apcaccess status

# Watch events in real-time
sudo tail -f /var/log/apcupsd.events
```

### Test Shutdown Script (Without Actually Shutting Down)

```bash
# Check script syntax
bash -n /usr/local/bin/lightning-shutdown.sh

# Dry run - manually stop services one at a time
sudo systemctl status loopd lnd bitcoind
```

### Test Full Power Failure (Carefully!)

1. Ensure you have a recent channel backup
2. Unplug the UPS from wall power
3. Watch `apcaccess status` as battery drains (or wait for BATTERYLEVEL threshold)
4. Observe graceful shutdown in `/var/log/lightning-shutdown.log`
5. Plug wall power back in
6. Verify server auto-boots and services start

---

## Monitoring Commands

```bash
# UPS status
apcaccess status

# Recent power events
sudo tail -20 /var/log/apcupsd.events

# Shutdown log
sudo tail -50 /var/log/lightning-shutdown.log

# Service status
sudo systemctl status bitcoind lnd loopd

# Check if services are set to start on boot
sudo systemctl is-enabled bitcoind lnd loopd
```

---

## Troubleshooting

### UPS Not Detected

```bash
# Check USB connection
lsusb | grep -i "power\|apc\|ups"

# Check apcupsd logs
sudo journalctl -u apcupsd -n 50

# Try restarting apcupsd
sudo systemctl restart apcupsd
```

### Server Doesn't Auto-Boot

1. Check BIOS "Restore on AC Power Loss" setting
2. Some boards need "Last State" instead of "Power On"
3. Check that power supply is connected to UPS output

### Services Don't Start in Order

```bash
# Check service dependencies
systemctl list-dependencies lnd.service

# Verify After= and Requires= in service files
sudo systemctl cat lnd.service | grep -E "After|Requires"
```

### LND Won't Unlock Automatically

See [lnd-unlock.sh setup](#lnd-unlockservice-auto-unlock-wallet-on-boot) - requires storing wallet password securely.

---

## Security Considerations

1. **Wallet password storage**: If using auto-unlock, the password file should be readable only by the LND user
   ```bash
   chmod 600 ~/.lnd/wallet_password
   ```

2. **Log file permissions**: Shutdown logs may contain sensitive timing info
   ```bash
   sudo chmod 640 /var/log/lightning-shutdown.log
   ```

3. **Remote access**: Consider VPN or SSH tunnel for remote monitoring during outages

---

## Next Steps

- [System Overview](../architecture/SYSTEM_OVERVIEW.md) - Full infrastructure architecture
- [Getting Started](GETTING_STARTED.md) - Complete setup guide
- [Payment Flow](../architecture/PAYMENT_FLOW.md) - How Lightning payments work

---

*This guide documents production infrastructure that has protected a Lightning node through multiple power events since September 2025.*
