# Getting Started: The Shopping List

Everything you need to build a sovereign app. All of this exists today.

---

## 1. Development Environment

### Claude Code (AI Coding Assistant)

**What it is**: An agentic AI that can read files, write code, run commands, and deploy to servers.

**Install**:
- Visit [claude.ai/claude-code](https://claude.ai/claude-code)
- Available for Mac, Windows, Linux
- Free tier available to start

**Why it matters**: This is how one person builds what used to require a team.

### Local Development Tools

```bash
# macOS
brew install git node python3 ffmpeg

# Ubuntu/Debian
sudo apt install git nodejs npm python3 ffmpeg

# Windows
# Install Git for Windows, Node.js LTS, Python 3, FFmpeg
```

---

## 2. Lightning Node

### Option A: Self-Hosted LND (Most Sovereign)

**Hardware**: Any always-on computer (old laptop, Raspberry Pi 4+, server hardware)

**Software**:
- Bitcoin Core (full or pruned node)
- LND (Lightning Network Daemon)

**Pros**:
- Maximum sovereignty
- No monthly fees
- Your keys, your coins

**Cons**:
- Requires uptime management
- Hardware failure risk
- More setup complexity

**Resources**:
- [LND Installation Guide](https://docs.lightning.engineering/lightning-network-tools/lnd/run-lnd)
- [RaspiBolt Guide](https://raspibolt.org/) (Raspberry Pi focused)

### Option B: BTCPay's Built-in Node (Simpler)

BTCPay Server can run its own Lightning node in Docker.
Everything on one VPS. Simpler but less sovereign.

**Pros**:
- Single deployment
- Managed Docker containers
- Easier setup

**Cons**:
- VPS provider has access to your node
- Higher VPS requirements
- Less separation of concerns

---

## 3. BTCPay Server

**What it is**: Open-source payment processor. Creates invoices, handles webhooks, gives you that QR code that works with any wallet.

**Deployment**:

```bash
# On a fresh VPS (Ubuntu 22.04 recommended)
# Minimum: 2GB RAM, 80GB storage

# Clone and run setup
git clone https://github.com/btcpayserver/btcpayserver-docker
cd btcpayserver-docker

# Configure for pruned node (saves ~400GB storage)
export BTCPAYGEN_ADDITIONAL_FRAGMENTS="opt-save-storage-xs"
export BTCPAY_HOST="btcpay.yourdomain.com"
export LETSENCRYPT_EMAIL="you@email.com"

# Run setup
. ./btcpay-setup.sh -i
```

**What's inside**: Multiple services in one Docker deployment - Bitcoin Core, BTCPay Server, database, reverse proxy, and more. Don't reinvent this wheel.

**Cost**: ~$20-40/month VPS

---

## 4. VPS Hosting

**The point**: You can use any provider. That's the sovereignty.

**Popular options**:
- Linode
- DigitalOcean
- Vultr
- Hetzner
- OVH

**Recommended specs**:

| Server | CPU | RAM | Storage | Purpose |
|--------|-----|-----|---------|---------|
| Web App | 2 | 4GB | 50GB + block storage | Your application |
| BTCPay | 2 | 4GB | 80GB | Payment processing |

**Why it matters**: If one provider becomes hostile, migrate in hours.

---

## 5. Web Application Stack

**Keep it simple**:

```
Frontend:
├── HTML5
├── CSS3
├── Vanilla JavaScript
└── (Optional) HLS.js for video

Backend:
├── Node.js (API server)
├── Express.js (routing)
└── PM2 (process manager)

Video Processing (if applicable):
├── FFmpeg (transcoding)
├── Python (automation scripts)
└── yt-dlp (downloading)
```

**Why vanilla**: No framework lock-in. Easier for AI to work with. Simpler debugging.

---

## 6. Domain & SSL

**Domain**: Any registrar (Namecheap, Cloudflare, etc.)

**SSL**: Let's Encrypt (free, auto-renewing)

```bash
# Using certbot
sudo apt install certbot python3-certbot-apache
sudo certbot --apache -d yourdomain.com
```

---

## Monthly Cost Breakdown

| Component | Cost |
|-----------|------|
| Web Server VPS | $40-80 |
| BTCPay Server VPS | $20-40 |
| Block Storage | $20-50 |
| VPS Backups | $10-20 |
| Domain | ~$12/year |
| Lightning Node | $0 (self-hosted) |
| **Total** | **Under $200/month** |

Costs vary by provider and storage needs. The point: it's cheap enough to experiment.

**Break-even**: A few hundred paying users covers infrastructure.

---

## What You DON'T Need

- ❌ A team of developers
- ❌ VC funding
- ❌ Payment processor approval
- ❌ User account infrastructure
- ❌ GDPR compliance overhead
- ❌ Years of experience

---

## First Steps

### Day 1: Install Claude Code
Get comfortable with the agentic workflow. Try:
- "Create a new folder called test"
- "Create a simple HTML page"
- "Add some CSS styling"

### Week 1: Set Up Infrastructure
- Provision VPS instances
- Install BTCPay Server
- Get SSL certificates

### Week 2: Build Your MVP
- Create basic frontend
- Implement payment flow
- Test with small amounts

### Week 3+: Iterate
- Add features based on user feedback
- Refine the experience
- Scale as needed

---

## Resources

- [BTCPay Server Docs](https://docs.btcpayserver.org/)
- [LND Developer Docs](https://docs.lightning.engineering/)
- [Claude Code](https://claude.ai/claude-code)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)

---

## Next Steps

- [BTCPay Setup Guide](BTCPAY_SETUP.md)
- [UPS & Graceful Shutdown](UPS_AND_GRACEFUL_SHUTDOWN.md) - Protect your Lightning node from power failures
- [CLAUDE.md Template](../templates/CLAUDE_MD_TEMPLATE.md)
