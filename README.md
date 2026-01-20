# Sovereign Apps: Building Lightning-Native Platforms with AI

**A reference architecture for building censorship-resistant, privacy-preserving content platforms.**

---

## What is a Sovereign App?

A sovereign app is software you fully control:

- **Your payment rails** - You run your own Lightning node
- **Portable infrastructure** - Standard VPS, migrate in hours, no vendor lock-in
- **Accounts optional** - No-KYC payments with instant settlement enable stateless auth
- **Open source stack** - Every layer is transparent
- **No permission needed** - Publish what you want, accept payments from anyone

Not an app that asks permission. An app that doesn't need it.

---

## The Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Payments** | LND + BTCPay Server | Accept Lightning/Bitcoin without intermediaries |
| **Backend** | Node.js + Python | API server, video processing |
| **Frontend** | HTML/CSS/JS | No frameworks required |
| **Hosting** | Any VPS provider | Portable, migratable |
| **Development** | Claude Code | AI-assisted building |

**Infrastructure**: ~$150-200/month + channel capital (recoverable investment)

---

## What's in This Repo

```
sovereign-app-architecture/
├── architecture/
│   ├── SYSTEM_OVERVIEW.md      # High-level architecture diagram
│   └── PAYMENT_FLOW.md         # How Lightning payments work
├── guides/
│   ├── GETTING_STARTED.md      # The shopping list
│   ├── BTCPAY_SETUP.md         # Quick BTCPay configuration
│   ├── SOVEREIGNTY_SPECTRUM.md # Custodial → Self-hosted options
│   └── UPS_AND_GRACEFUL_SHUTDOWN.md  # Power protection & recovery
├── scripts/
│   └── ups-integration/        # Ready-to-use UPS scripts
│       ├── install.sh          # Automated installer
│       ├── lightning-shutdown.sh  # Graceful shutdown script
│       ├── backup_scb.sh       # Channel backup script
│       └── apcupsd.conf        # UPS daemon config
├── templates/
│   └── CLAUDE_MD_TEMPLATE.md   # Example AI assistant instructions
└── resources/
    └── LINKS.md                # Useful documentation links
```

---

## The Origin Story

This architecture powered [Hyperdope](https://hyperdope.com), a Bitcoin-native video platform built by one person in three months using AI-assisted development.

**Key metrics:**
- 848 commits
- 128k+ lines of code
- 227 videos monetized
- 6,000+ sats processed
- Zero user accounts

The patterns here aren't theoretical. They're production-tested.

---

## Who This Is For

**Creators** who want to own their platform and keep 100% of payments.

**Builders** looking for a blueprint to ship their own sovereign app.

**Developers** curious about AI-assisted development workflows.

---

## Trade-offs to Consider

This approach requires:
- **Operational responsibility** - You maintain the infrastructure (UPS, backups, monitoring)
- **Learning curve** - Comfort with Linux, Bitcoin, Lightning, and APIs
- **Capital commitment** - Beyond infrastructure costs, Lightning channels require locked funds (typically 1-10M sats)
- **Time investment** - Production system typically takes 2-3 months with AI-assisted development

**Not sure?** [Sovereignty Spectrum](guides/SOVEREIGNTY_SPECTRUM.md) covers the full range from custodial to fully sovereign - choose your starting point.

---

## Quick Start

1. **Try it**: Visit [hyperdope.com](https://hyperdope.com) and unlock a video with Lightning
2. **Learn**: Read the [System Overview](architecture/SYSTEM_OVERVIEW.md)
3. **Build**: Follow the [Getting Started Guide](guides/GETTING_STARTED.md)
4. **Protect**: Set up [UPS & Graceful Shutdown](guides/UPS_AND_GRACEFUL_SHUTDOWN.md) for your node

---

## Resources

- **Live demo**: [hyperdope.com](https://hyperdope.com)
- **Claude Code**: [claude.ai/claude-code](https://claude.ai/claude-code)
- **BTCPay Server**: [btcpayserver.org](https://btcpayserver.org)
- **LND**: [github.com/lightningnetwork/lnd](https://github.com/lightningnetwork/lnd)

---

## Contact

- **X/Twitter**: [@EricRHadley](https://x.com/EricRHadley)
- **Site**: [hyperdope.com](https://hyperdope.com)

---

*Built with Lightning and AI. No permission required.*
