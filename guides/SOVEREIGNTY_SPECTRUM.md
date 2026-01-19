# Sovereignty Spectrum: Choose Your Path

Not everyone needs (or wants) maximum sovereignty from day one. This guide documents the most sovereign path, but here's the full spectrum of options.

---

## The Trade-off Triangle

```
                    SOVEREIGNTY
                        △
                       /|\
                      / | \
                     /  |  \
                    /   |   \
                   /    |    \
                  /     |     \
                 /      |      \
                /       |       \
               /________|________\
          EASE OF USE        COST

Pick two. The third suffers.
```

---

## Level 1: Custodial (Easiest, Least Sovereign)

**You don't run any infrastructure. A third party handles everything.**

### Solutions

| Service | Description | Best For |
|---------|-------------|----------|
| [LNbits](https://lnbits.com) | Lightweight accounts layer, extensions ecosystem | Prototyping, hackathons |
| [Alby](https://getalby.com) | Browser extension + custodial wallet | WebLN integration |
| [OpenNode](https://opennode.com) | Payment processor API | E-commerce integration |
| [Strike API](https://strike.me) | Fiat on/off ramps + Lightning | Mainstream apps |
| [ZBD](https://zbd.gg) | Gaming-focused Lightning API | Games, rewards |

### Trade-offs

| Pros | Cons |
|------|------|
| Start in minutes | Third party holds your funds |
| No infrastructure to manage | Can be deplatformed |
| No channel management | Privacy compromised |
| Professional uptime | Counterparty risk |

### When to Use

- Hackathons and prototypes
- Learning Lightning development
- Very small amounts (<$100)
- When speed-to-market matters most

### When to Avoid

- Production apps with real revenue
- Privacy-sensitive applications
- Amounts you can't afford to lose
- When "not your keys, not your coins" matters

---

## Level 2: Hosted Node (Easier, More Sovereign)

**You control the keys, but someone else runs the infrastructure.**

### Solutions

| Service | Description | Price Range |
|---------|-------------|-------------|
| [Voltage](https://voltage.cloud) | Hosted LND nodes, you hold keys | $10-50/month |
| [BTCPay Cloud](https://btcpayserver.org) | Hosted BTCPay instances | Varies |
| [Nodeless.io](https://nodeless.io) | Lightning infrastructure API | Usage-based |

### Trade-offs

| Pros | Cons |
|------|------|
| Your keys, your coins | Provider sees your transactions |
| Professional uptime (99.9%+) | Monthly costs |
| No hardware to manage | Dependent on provider |
| Automatic updates | Less customization |
| Built-in backups | Can't run custom software |

### When to Use

- Production apps where uptime matters
- Teams without infrastructure expertise
- When you need to move fast but want sovereignty
- Startups validating product-market fit

### When to Avoid

- Maximum privacy requirements
- Full customization needs
- When you want to learn the full stack

---

## Level 3: Home Node (Sovereign, More Effort)

**You run everything on hardware you physically control.**

### Solutions

| Platform | Description | Hardware Cost |
|----------|-------------|---------------|
| [Umbrel](https://umbrel.com) | Beautiful UI, one-click apps | $200-500 |
| [Start9](https://start9.com) | Embassy OS, privacy-focused | $300-600 |
| [RaspiBlitz](https://raspiblitz.org) | Raspberry Pi focused, DIY | $150-300 |
| [MyNode](https://mynodebtc.com) | Another Pi-based option | $150-300 |
| [Citadel](https://runcitadel.space) | Umbrel fork, community-driven | $200-500 |

### What You Get

All of these include:
- Full Bitcoin node
- Lightning node (LND or CLN)
- BTCPay Server (one-click install)
- Automatic channel backups
- Web-based management UI
- App store for additional services

### Trade-offs

| Pros | Cons |
|------|------|
| Full sovereignty | Home IP exposed to peers |
| Physical possession | Home internet reliability |
| Great UIs | Power outage risk |
| App ecosystems | Hardware maintenance |
| Learning experience | Initial setup time |
| One-time hardware cost | Sync takes days |

### When to Use

- Privacy is paramount
- You want to learn the full stack
- Reliable home internet + UPS
- Long-term commitment to running infrastructure

### When to Avoid

- Unreliable home internet/power
- Need 99.99% uptime for business
- No technical aptitude
- Frequently moving/traveling

### Recommended Hardware (2025)

```
Minimum:
- Raspberry Pi 5 (8GB) - Pi 4 is now underpowered
- 1TB+ NVMe SSD
- Quality power supply
- UPS battery backup

Better:
- Mini PC (Intel N100 or better)
- 2TB NVMe SSD
- 16GB+ RAM
- Gigabit ethernet
```

---

## Level 4: VPS Self-Hosted (Most Sovereign, Most Effort)

**This is what the rest of this guide documents.**

You run your own infrastructure on VPS providers, maintaining full control while getting datacenter reliability.

### Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Web App VPS   │     │  BTCPay VPS     │     │ Lightning Node  │
│   (Linode)      │────▶│  (Linode)       │────▶│ (Home Server)   │
│   $20/month     │     │  $20/month      │     │ + UPS backup    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Trade-offs

| Pros | Cons |
|------|------|
| Maximum control | Most setup complexity |
| Datacenter uptime | Must manage everything |
| Can migrate anywhere | Higher monthly costs |
| Full customization | Security is your responsibility |
| Professional infrastructure | Steep learning curve |

### When to Use

- Production applications
- Maximum sovereignty + reliability
- When you need custom configurations
- Long-term infrastructure investment

### When to Avoid

- Just learning/prototyping
- No Linux/sysadmin experience
- Need something working today

---

## Hybrid Approaches

Many operators combine approaches strategically:

### Development → Production Pipeline

```
Prototype     →    Validate    →    Scale
(Custodial)       (Voltage)        (Self-hosted)
   |                 |                  |
LNbits/Alby    Hosted LND         Own infrastructure
```

### Split by Function

```
Receive payments: Self-hosted LND (maximum sovereignty)
Spend/route:      Mobile wallet (convenience)
Development:      Testnet + Polar (free)
```

### Geographic Redundancy

```
Primary:  Self-hosted VPS (your infrastructure)
Backup:   Umbrel at home (disaster recovery)
```

---

## WebLN: Better UX Without Sacrificing Backend Sovereignty

Even with a fully sovereign backend, you can dramatically improve user experience with **WebLN**.

### What is WebLN?

WebLN is a standard that lets websites request Lightning payments directly from browser extensions like Alby.

**Without WebLN:**
1. User clicks "Pay"
2. Your server generates invoice
3. User sees QR code
4. User opens separate wallet app
5. User scans QR code
6. User confirms payment

**With WebLN:**
1. User clicks "Pay"
2. Alby popup appears
3. User clicks "Confirm"
4. Done

### Integration Example

```javascript
// Check for WebLN support
async function payInvoice(bolt11Invoice) {
  // Try WebLN first (Alby, etc.)
  if (typeof window.webln !== 'undefined') {
    try {
      await window.webln.enable();
      const result = await window.webln.sendPayment(bolt11Invoice);
      console.log('Payment preimage:', result.preimage);
      return { success: true, method: 'webln' };
    } catch (e) {
      console.log('WebLN failed, falling back to QR');
    }
  }

  // Fall back to QR code display
  showQRCode(bolt11Invoice);
  return { success: false, method: 'qr_fallback' };
}
```

### Key Point

WebLN improves your **frontend UX** without changing your **backend sovereignty**. Your self-hosted LND still generates the invoices and receives the payments.

---

## Decision Framework

### Answer These Questions

1. **How much can you lose?**
   - < $100: Custodial is fine
   - $100-$10,000: Hosted or home node
   - > $10,000: Self-hosted with proper security

2. **What's your uptime requirement?**
   - "It's fine if it goes down sometimes": Home node
   - "Should be up 99% of time": Hosted or VPS
   - "Must be up 99.9%+": Professional VPS setup

3. **What's your technical level?**
   - "What's SSH?": Umbrel or custodial
   - "I can follow tutorials": Start9 or hosted
   - "I manage Linux servers": Self-hosted VPS

4. **How much time can you invest?**
   - A few hours: Custodial or hosted
   - A weekend: Umbrel/Start9
   - Weeks of learning: Full self-hosted

### Quick Reference

| Situation | Recommendation |
|-----------|----------------|
| Hackathon this weekend | LNbits + Alby |
| MVP for startup | Voltage + BTCPay |
| Personal project, want to learn | Umbrel at home |
| Production app, need reliability | This guide (VPS self-hosted) |
| Maximum privacy | Home node with Tor |

---

## Migration Paths

### Custodial → Sovereign

1. Start with LNbits/Alby for prototyping
2. Move to Voltage when you have paying users
3. Self-host when revenue justifies infrastructure investment

### Home → VPS

When your Umbrel outgrows home internet:
1. Keep Umbrel as backup/development
2. Deploy BTCPay on VPS
3. Connect VPS BTCPay to home LND via Tor/VPN
4. Or: Run everything on VPS, Umbrel becomes cold backup

---

## Resources

### Node Platforms
- [Umbrel](https://umbrel.com) - Most popular, great UI
- [Start9](https://start9.com) - Privacy-focused, excellent docs
- [RaspiBlitz](https://raspiblitz.org) - DIY friendly

### Hosted Services
- [Voltage](https://voltage.cloud) - Hosted LND
- [Alby Hub](https://albyhub.com) - Self-custodial in the cloud

### WebLN
- [WebLN Guide](https://webln.guide) - Integration documentation
- [Alby](https://getalby.com) - Most popular WebLN wallet

### Learning
- [Polar](https://lightningpolar.com) - Local Lightning network for development
- [Lightning Engineering Docs](https://docs.lightning.engineering)

---

*The most sovereign option isn't always the right option. Start where you are, and level up as you grow.*
