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

This architecture powered [Hyperdope](https://hyperdope.com), a Bitcoin-native video platform.

**Built by one person in three months using AI-assisted development.**

The patterns here aren't theoretical - they're running in production. Try it yourself: unlock a video with Lightning and see what "no accounts, no signup" actually feels like.

---

## Who This Is For

**You want to control your own platform** - Your content decisions. Your algorithm. Your rules. Not theirs.

**You want sovereign payment rails** - Direct Lightning payments, no payment processor taking 30% or deciding you're "high risk." Keep 100% of what you earn.

**You've been deplatformed** - or you see it coming. You need infrastructure that doesn't depend on anyone's permission.

**You thought you couldn't build this alone** - No engineering team. No funding. But with AI-assisted development, the barrier is lower than you think.

---

## Zero Support Architecture

Every design choice asks: "Does this add operational burden?"

| Choice | What It Eliminates |
|--------|-------------------|
| **Payment proof = authentication** | User accounts, password recovery, support tickets |
| **No email collection** | GDPR compliance, breach liability |
| **No comments** | Moderation queue, abuse reports |
| **Stateless tokens** | Session storage, database scaling |
| **Hash-based IDs** | Database lookups - the hash IS the file path |

**The goal**: A support organization of zero. AI can help you build software, but it can't staff a support desk. The architecture must eliminate that need.

See [System Overview](architecture/SYSTEM_OVERVIEW.md#design-philosophy-zero-operational-overhead) for details.

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

1. **Explore**: See the [Architecture Overview](https://hyperdope.com/architecture.html) for visual diagrams
2. **Try it**: Visit [hyperdope.com](https://hyperdope.com) and unlock a video with Lightning
3. **Learn**: Read the [System Overview](architecture/SYSTEM_OVERVIEW.md)
4. **Build**: Follow the [Getting Started Guide](guides/GETTING_STARTED.md)
5. **Protect**: Set up [UPS & Graceful Shutdown](guides/UPS_AND_GRACEFUL_SHUTDOWN.md) for your node

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
