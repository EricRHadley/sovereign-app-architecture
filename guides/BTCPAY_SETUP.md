# BTCPay Server Quick Setup

A minimal guide to get BTCPay running for your sovereign app.

---

## Prerequisites

- Fresh VPS (Ubuntu 22.04 LTS recommended)
- Domain name pointed at your VPS IP
- SSH access
- Adequate storage headroom for a typical pruned node sync

---

## 1. Basic Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker (BTCPay uses Docker)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER
# Log out and back in for this to take effect
```

---

## 2. Install BTCPay Server

```bash
# Clone the BTCPay Docker repository
git clone https://github.com/btcpayserver/btcpayserver-docker
cd btcpayserver-docker

# Set environment variables
export BTCPAY_HOST="btcpay.yourdomain.com"
export NBITCOIN_NETWORK="mainnet"
export BTCPAYGEN_CRYPTO1="btc"
export BTCPAYGEN_LIGHTNING="lnd"
# Alternative: export BTCPAYGEN_LIGHTNING="clightning" for Core Lightning
export LETSENCRYPT_EMAIL="you@email.com"

# Use pruned node to reduce storage footprint
export BTCPAYGEN_ADDITIONAL_FRAGMENTS="opt-save-storage-xs"

# Run the setup
. ./btcpay-setup.sh -i
```

---

## 3. Wait for Sync

The Bitcoin node needs to sync with the network. This takes time.

**Expected sync time:**
- Fresh node: 2-7 days depending on hardware and internet
- Pruned node: Still processes all blocks, just doesn't store them all
- Don't proceed until sync is 100% complete

```bash
# Check sync progress
docker logs -f btcpayserver_bitcoind

# Check disk usage during sync
df -h

# Check sync percentage (look for "progress=")
docker exec btcpayserver_bitcoind bitcoin-cli getblockchaininfo | grep verificationprogress
```

---

## 4. Create Your Store

1. Visit `https://btcpay.yourdomain.com`
2. Create an account (first user becomes admin)
3. Create a new store
4. Enable Lightning in store settings

---

## 5. Connect External Lightning Node (Optional)

If you're running your own LND node elsewhere:

**On your LND node:**
```bash
# Get your macaroon (hex format)
xxd -p -c 1000 ~/.lnd/data/chain/bitcoin/mainnet/admin.macaroon

# Get your TLS cert fingerprint
openssl x509 -noout -fingerprint -sha256 -in ~/.lnd/tls.cert
```

**In BTCPay:**
1. Store Settings → Lightning → Setup
2. Choose "Use custom node"
3. Connection string format:
```
type=lnd-rest;server=https://your-node-ip:8080/;macaroon=HEX;certthumbprint=FINGERPRINT
```

**Security Warning**: Never expose LND ports (8080, 10009) directly to the public internet.

### Connectivity Options

The challenge: BTCPay on a VPS needs to securely reach LND on your home network. Your home IP is probably dynamic, and you don't want to expose it anyway. Here are your options:

#### Option A: All-in-One at Home (Simplest Architecture)

Run BTCPay and LND on the same machine. Everything talks over localhost.

**Umbrel/Start9**: These bundle BTCPay + LND together. Install the BTCPay app from their app store. Done. Access via Tor onion address or their tunnel services.

**Manual**: Install BTCPay Docker on your Lightning node machine. Same setup as above, but `your-node-ip` is `localhost`.

**Trade-offs**:
- ✅ No network complexity
- ✅ Everything on one box
- ⚠️ Need to expose BTCPay web interface (Tor, dynamic DNS, or tunnel)
- ⚠️ Tor can be slow for customers

#### Option B: Tailscale (Easiest for Separate Machines)

Tailscale creates a private mesh network between your machines. BTCPay connects to LND via Tailscale IP.

```bash
# On both BTCPay VPS and Lightning node:
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Get the Tailscale IP of your Lightning node:
tailscale ip -4
# Example: 100.x.y.z
```

**In BTCPay**, use the Tailscale IP:
```
type=lnd-rest;server=https://100.x.y.z:8080/;macaroon=HEX;certthumbprint=FINGERPRINT
```

**Trade-offs**:
- ✅ Very easy setup
- ✅ No port forwarding, no static IP needed
- ✅ Works through NAT and firewalls
- ⚠️ Depends on Tailscale service (free tier available)

#### Option C: Reverse SSH Tunnel (No External Dependencies)

Your home node initiates an outbound SSH connection to a relay server. BTCPay connects to the relay, which forwards to your node.

**Architecture**:
```
[BTCPay VPS] ----> [Tunnel Server :8080] <==== [Home LND Node]
                   (public IP)            (reverse SSH tunnel)
```

**Setup on tunnel server** (any cheap VPS with a static IP):
```bash
# Enable GatewayPorts in /etc/ssh/sshd_config
GatewayPorts yes
sudo systemctl restart sshd
```

**Setup on home Lightning node**:
```bash
# Install autossh for persistent tunnels
sudo apt install autossh

# Create systemd service: /etc/systemd/system/lightning-tunnel.service
[Unit]
Description=Lightning SSH Tunnel
After=network.target

[Service]
Type=simple
User=youruser
ExecStart=/usr/bin/autossh -M 0 -N \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=3 \
  -o ExitOnForwardFailure=yes \
  -R 8080:localhost:8080 \
  -R 10009:localhost:10009 \
  tunnel-user@tunnel-server-ip
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target

# Enable and start
sudo systemctl enable lightning-tunnel
sudo systemctl start lightning-tunnel
```

**In BTCPay**, connect to the tunnel server:
```
type=lnd-rest;server=https://tunnel-server-ip:8080/;macaroon=HEX;certthumbprint=FINGERPRINT
```

**Trade-offs**:
- ✅ No external dependencies (just SSH)
- ✅ Home IP stays private
- ✅ Works through any NAT/firewall
- ⚠️ Requires a second VPS as relay (~$5/month)
- ⚠️ More setup complexity

#### Option D: WireGuard VPN (Self-Hosted)

Similar to Tailscale but self-hosted. Create a VPN between BTCPay VPS and home node.

**Trade-offs**:
- ✅ No external dependencies
- ✅ Very performant
- ⚠️ More complex setup than Tailscale
- ⚠️ Need to manage keys and configs yourself

See the [WireGuard Quick Start](https://www.wireguard.com/quickstart/) for setup instructions.

### Which Should You Choose?

| Situation | Recommendation |
|-----------|----------------|
| Just starting out | Umbrel/Start9 (all-in-one) |
| Want separate VPS for BTCPay | Tailscale (easiest) |
| Want zero external dependencies | Reverse SSH tunnel |
| Already use WireGuard | WireGuard |

**AI-assisted setup**: All of these options are well-documented. Claude Code can walk you through any of them step by step.

---

## 6. Create API Credentials

For your app to create invoices:

1. Account Settings → API Keys
2. Create new API key
3. Grant permissions:
   - `btcpay.store.cancreateinvoice`
   - `btcpay.store.canviewinvoices`

Save the API key securely.

---

## 7. Configure Webhooks

Webhooks notify your app when payments arrive.

1. Store Settings → Webhooks
2. Create webhook:
   - Payload URL: `https://yourapp.com/api/btcpay-webhook`
   - Events: `Invoice settled`, `Invoice expired`
3. Copy the webhook secret

---

## 8. Test Everything

Test your setup by creating an invoice through BTCPay's web interface first. Once that works, use the API documentation to create invoices programmatically.

**Important**: API formats change between BTCPay versions. Always consult the current [Greenfield API Reference](https://docs.btcpayserver.org/API/Greenfield/v1/) for your version rather than copying code snippets that may be outdated.

---

## Common Issues

### Bitcoin node won't sync
- Check disk space: `df -h`
- Check Docker logs: `docker logs btcpayserver_bitcoind`

### Lightning not connecting
- Verify your node is reachable from BTCPay server
- Check firewall rules allow the connection
- Verify macaroon and cert are correct

### Webhooks not firing
- Check webhook URL is publicly accessible
- Verify SSL certificate is valid
- Check BTCPay webhook logs

---

## Security Checklist

- [ ] Use strong admin password
- [ ] Enable 2FA for admin account
- [ ] Keep server updated: `sudo apt update && sudo apt upgrade`
- [ ] Configure UFW firewall
- [ ] Set up Fail2ban
- [ ] Regular backups of `/var/lib/docker/volumes`

---

## Useful Commands

```bash
# Restart BTCPay
cd ~/btcpayserver-docker
./btcpay-restart.sh

# Update BTCPay
./btcpay-update.sh

# View logs
docker logs -f btcpayserver_btcpayserver

# Check disk usage
docker system df
```

---

## Resources

- [BTCPay Server Documentation](https://docs.btcpayserver.org/)
- [BTCPay Server GitHub](https://github.com/btcpayserver/btcpayserver)
- [BTCPay API Reference](https://docs.btcpayserver.org/API/Greenfield/v1/)
