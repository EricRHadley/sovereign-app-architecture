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

**Hardware**: Any always-on computer
- Raspberry Pi 5 (8GB) - Pi 4 is now underpowered for full Bitcoin node
- Mini PC (Intel N100, NUC, etc.)
- Old laptop or desktop
- Server hardware

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

### Option C: Easier Starting Points

If self-hosting feels overwhelming, consider starting with:
- **[Umbrel](https://umbrel.com)** or **[Start9](https://start9.com)** - Node-in-a-box solutions with great UIs
- **[Voltage](https://voltage.cloud)** - Hosted LND nodes (you hold keys)

See [Sovereignty Spectrum](SOVEREIGNTY_SPECTRUM.md) for the full range of options.

### Channel Management Basics

Before you can receive Lightning payments, you need **inbound liquidity** - sats on the remote side of your channels.

**Opening Channels:**
```bash
# Fund your LND wallet first
lncli newaddress p2wkh
# Send Bitcoin to this address, wait for confirmations

# Open a channel (find peers at 1ml.com or amboss.space)
lncli openchannel --node_key=<peer_pubkey> --local_amt=500000
```

**Getting Inbound Liquidity:**

This is the #1 operational challenge for Lightning merchants:

| Method | Description | Cost |
|--------|-------------|------|
| Lightning Loop | Submarine swaps (Lightning → on-chain) | ~0.1-0.5% |
| Ask peers | Request others open channels to you | Free (favors) |
| Liquidity marketplaces | Magma, Pool | Variable |
| Dual-funded channels | Both parties contribute | Requires CLN or recent LND |

**How Much Do You Need?**

- Start with 500K-1M sats inbound for testing
- Scale based on expected daily payment volume × 3-7 days buffer
- Monitor with: `lncli listchannels | jq '.channels[] | {alias: .peer_alias, local: .local_balance, remote: .remote_balance}'`

**When Channels Get Unbalanced:**

After receiving many payments, your channels fill up (high local, low remote). Options:
- **Loop Out**: Move sats to on-chain, restoring inbound capacity
- **Circular rebalance**: Pay yourself through other channels
- **Spend**: Actually use your Lightning sats

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

## Cost Breakdown

### Monthly Infrastructure
| Component | Cost |
|-----------|------|
| Web Server VPS | $40-80 |
| BTCPay Server VPS | $20-40 |
| Block Storage | $20-50 |
| VPS Backups | $10-20 |
| Domain | ~$12/year |
| Lightning Node | $0 (self-hosted) |
| **Total** | **~$150-200/month** |

### Channel Capital (One-time, Recoverable)
Lightning channels require locked funds for liquidity:
- **Minimum to start**: 500K-1M sats
- **Production level**: 5-15M sats typical
- **This is an investment, not a cost** - funds are recoverable when channels close

### Break-even
Infrastructure costs are low enough that a few hundred paying users covers monthly expenses. The real investment is your time and channel capital.

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

### Getting Started: Install Claude Code
Get comfortable with the agentic workflow. Try:
- "Create a new folder called test"
- "Create a simple HTML page"
- "Add some CSS styling"

### Realistic Timeline

Building a production sovereign app typically takes **2-3 months** with AI-assisted development:

**Phase 1: Infrastructure** (1-2 weeks)
- Provision VPS instances
- Install BTCPay Server, wait for sync
- Configure SSL, domains, firewalls

**Phase 2: Payment Integration** (3-4 weeks)
- BTCPay API integration
- Token generation and validation
- Content protection (if applicable)

**Phase 3: Hardening** (2-4 weeks)
- Testing with real payments
- Security review
- UPS, backups, monitoring setup

**Phase 4: Launch + Operations** (ongoing)
- Channel management and liquidity
- Content creation
- Iterate based on usage

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
