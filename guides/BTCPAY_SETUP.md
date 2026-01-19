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
export LETSENCRYPT_EMAIL="you@email.com"

# Use pruned node to reduce storage footprint
export BTCPAYGEN_ADDITIONAL_FRAGMENTS="opt-save-storage-xs"

# Run the setup
. ./btcpay-setup.sh -i
```

---

## 3. Wait for Sync

The Bitcoin node needs to sync with the network. This takes time.

```bash
# Check sync progress
docker logs -f btcpayserver_bitcoind

# Check disk usage during sync
df -h
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
