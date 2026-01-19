# UPS Integration Scripts for Lightning Nodes

This directory contains scripts for protecting your Lightning node from power failures.

## Quick Start

```bash
# Run as root
sudo ./install.sh
```

The installer will:
1. Install apcupsd (UPS monitoring daemon)
2. Configure graceful shutdown on low battery
3. Set up automatic channel backups every 5 minutes
4. Test UPS communication

## Files

| File | Purpose | Install Location |
|------|---------|------------------|
| `install.sh` | Automated installer | Run from this directory |
| `apcupsd.conf` | UPS daemon configuration | `/etc/apcupsd/apcupsd.conf` |
| `apccontrol.local` | Power event hooks | `/etc/apcupsd/apccontrol.local` |
| `lightning-shutdown.sh` | Graceful shutdown script | `/usr/local/bin/lightning-shutdown.sh` |
| `backup_scb.sh` | Channel backup script | `~/scripts/backup_scb.sh` |

## How It Works

### Power Failure Sequence

```
Wall Power Lost
      │
      ▼
UPS Battery Takes Over (instant)
      │
      ▼
apcupsd Monitors Battery Level
      │
      ├─── Battery > 20% ──► Continue Running
      │
      └─── Battery ≤ 20% ──► Trigger Shutdown
                                    │
                                    ▼
                         lightning-shutdown.sh
                              (~3.5 minutes)
                                    │
                                    ▼
                              Safe Power Off
```

### Shutdown Order

1. **Loop daemon** (immediate) - Depends on LND
2. **LND** (60 seconds) - Flush channel state
3. **Bitcoin Core** (120 seconds) - Write UTXO set
4. **Cleanup** (30 seconds) - Final process termination

### Power Restoration

When power returns:
1. BIOS auto-powers on the server (requires BIOS setting)
2. systemd starts services in dependency order
3. bitcoind → lnd → loopd
4. Node is fully operational without manual intervention

## Prerequisites

- Ubuntu/Debian Linux
- APC or compatible UPS with USB connection
- LND and Bitcoin Core running as systemd services
- BIOS configured for "Power On after AC Loss"

## Manual Installation

If you prefer to install manually:

```bash
# 1. Install apcupsd
sudo apt-get install apcupsd

# 2. Copy configuration
sudo cp apcupsd.conf /etc/apcupsd/
sudo cp apccontrol.local /etc/apcupsd/
sudo chmod +x /etc/apcupsd/apccontrol.local

# 3. Copy shutdown script
sudo cp lightning-shutdown.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/lightning-shutdown.sh

# 4. Edit the shutdown script for your setup
sudo nano /usr/local/bin/lightning-shutdown.sh
# Change LND_USER, LNCLI_PATH, etc.

# 5. Enable apcupsd
sudo sed -i 's/ISCONFIGURED=no/ISCONFIGURED=yes/' /etc/default/apcupsd
sudo systemctl restart apcupsd
sudo systemctl enable apcupsd

# 6. Set up channel backups
cp backup_scb.sh ~/scripts/
chmod +x ~/scripts/backup_scb.sh
crontab -e
# Add: */5 * * * * ~/scripts/backup_scb.sh
```

## Testing

### Check UPS Status
```bash
apcaccess status
```

### Test Shutdown Script (dry run)
```bash
# Just check syntax
bash -n /usr/local/bin/lightning-shutdown.sh

# Check service status first
sudo systemctl status bitcoind lnd loopd
```

### Full Power Test
1. Ensure you have recent channel backup
2. Unplug UPS from wall
3. Watch battery drain (or wait for threshold)
4. Observe shutdown in logs: `tail -f /var/log/lightning-shutdown.log`
5. Plug power back in
6. Verify server auto-boots and services start

## Monitoring Commands

```bash
# UPS status
apcaccess status

# Power events
sudo tail -f /var/log/apcupsd.events

# Shutdown log
sudo tail -f /var/log/lightning-shutdown.log

# Service status
sudo systemctl status apcupsd bitcoind lnd loopd
```

## Customization

### Change Shutdown Thresholds

Edit `/etc/apcupsd/apcupsd.conf`:

```
BATTERYLEVEL 20   # Shutdown at 20% battery
MINUTES 10        # Or when 10 minutes remain
```

### Change Wait Times

Edit `/usr/local/bin/lightning-shutdown.sh`:

```bash
LND_WAIT=60        # Time for LND to flush
BITCOIND_WAIT=120  # Time for Bitcoin Core
CLEANUP_WAIT=30    # Final cleanup
```

### Add Email Notifications

Edit `/etc/apcupsd/apccontrol.local` and add to the `powerout` case:

```bash
powerout)
    log "ALERT: Power failure detected"
    echo "Power failure at $(hostname)" | mail -s "UPS Alert" you@email.com
    ;;
```

## Troubleshooting

### UPS Not Detected
```bash
# Check USB connection
lsusb | grep -i "power\|apc\|ups"

# Check apcupsd logs
sudo journalctl -u apcupsd -n 50
```

### Server Won't Auto-Boot
- Check BIOS "Restore on AC Power Loss" setting
- Some boards need "Last State" instead of "Power On"

### Services Start Out of Order
```bash
# Check dependencies
systemctl list-dependencies lnd.service

# Verify service file
sudo systemctl cat lnd.service | grep -E "After|Requires"
```

## Security Notes

- Shutdown logs may contain timing information
- If using auto-unlock, protect the password file: `chmod 600 ~/.lnd/wallet_password`
- Consider the physical security of your UPS and server

## See Also

- [Full UPS Guide](../../guides/UPS_AND_GRACEFUL_SHUTDOWN.md) - Comprehensive documentation
- [System Overview](../../architecture/SYSTEM_OVERVIEW.md) - Full architecture
- [Getting Started](../../guides/GETTING_STARTED.md) - Initial setup
