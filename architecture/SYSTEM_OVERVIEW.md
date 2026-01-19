# System Architecture Overview

## High-Level Infrastructure

```
┌─────────────┐        ┌─────────────────┐        ┌─────────────────┐        ┌─────────────┐
│             │        │                 │        │                 │        │             │
│    Users    │───────▶│   Web Server    │───────▶│  BTCPay Server  │───────▶│  Lightning  │
│             │        │                 │        │                 │        │    Node     │
│  - Browser  │        │  - Apache/Nginx │        │  - Invoices     │        │             │
│  - Wallet   │        │  - Node.js API  │        │  - Webhooks     │        │  - LND      │
│  - No Acct  │        │  - HLS Video    │        │  - Bitcoin Core │        │  - Channels │
│             │        │                 │        │                 │        │             │
└─────────────┘        └─────────────────┘        └─────────────────┘        └─────────────┘
```

---

## The Three Layers

### Layer 1: Lightning Node (Foundation)

Your Lightning node is the financial foundation. It:
- Receives payments directly (no intermediary)
- Routes payments through the Lightning Network
- Maintains channel balances for liquidity

**Options:**
- **Self-hosted LND** on your own hardware (most sovereign)
- **BTCPay's built-in node** on your VPS (simpler setup)

**Key considerations:**
- Channel capacity determines how much you can receive
- AutoLoop can automate liquidity management
- Channel backups are critical (automate these!)

### Layer 2: BTCPay Server (Orchestration)

BTCPay Server is the glue between your app and your node:
- Creates Lightning invoices
- Generates unified QR codes (Lightning + on-chain)
- Fires webhooks when payments arrive
- Tracks payment history

**Deployment:**
- Docker container on a VPS (~$20/month)
- Pruned Bitcoin node uses only ~25GB
- Connects to your Lightning node over encrypted tunnel

### Layer 3: Web Application (Interface)

Your actual product. Key architectural choice:

**No User Accounts**

- No email collection
- No passwords to hash
- No personal data to protect or leak
- No GDPR compliance overhead

Lightning makes this possible. The payment itself is the authentication.

---

## Technology Stack

### Frontend
| Technology | Purpose |
|------------|---------|
| HTML5 Video | Native video playback |
| HLS.js | Adaptive streaming |
| Plyr.js | Video player UI |
| Vanilla JS | No framework dependencies |
| LocalStorage | Client-side token storage |

### Backend
| Technology | Purpose |
|------------|---------|
| Node.js | API server |
| PM2 | Process management |
| Python | Video processing workers |
| FFmpeg | HLS transcoding |
| Apache/Nginx | Static file serving |

### Payments
| Technology | Purpose |
|------------|---------|
| BTCPay Server | Invoice generation, webhooks |
| LND | Lightning Network daemon |
| Lightning Loop | Automated liquidity (optional) |
| HMAC-SHA256 | Token signing |

### Security
| Technology | Purpose |
|------------|---------|
| Stateless tokens | No server-side sessions |
| SSH tunnels | Secure node connections |
| UFW | Firewall |
| Fail2ban | Intrusion prevention |
| Automated backups | Channel + data protection |

---

## Data Flow

### Video Request (Unlocked)
```
Browser → Web Server → Serve HLS segments
```

### Video Request (Locked)
```
Browser → Web Server → Check token → Valid? → Serve segments
                                  → Invalid? → Return 403
```

### Payment Flow
```
User clicks unlock → Server creates BTCPay invoice → User pays QR
                                                          ↓
Server generates token ← Webhook fires ← BTCPay detects payment
         ↓
Token stored in browser localStorage
         ↓
User requests video → Token validated → Segments served
```

---

## Key Architectural Decisions

### 1. Stateless Authentication

Tokens contain all information needed to verify access:
- Video ID
- Access tier (24-hour vs forever)
- Expiration timestamp
- Cryptographic signature

Server validates by checking signature. No database lookup required.

### 2. No User Accounts

Benefits:
- Can't leak data you don't collect
- No password breach liability
- No GDPR/CCPA compliance burden
- Zero account creation friction

### 3. Separation of Concerns

Development machine (with Claude) only has access to web server.
Lightning node and BTCPay are on separate infrastructure.
Compromise of one doesn't compromise all.

### 4. Portable Infrastructure

Everything runs on standard VPS providers.
Migration to different provider takes hours, not weeks.
No vendor lock-in.

---

## Infrastructure Costs

| Component | Monthly Cost |
|-----------|-------------|
| Web Server VPS | $40-80 |
| BTCPay Server VPS | $20-40 |
| Block Storage | $20-50 |
| VPS Backups | $10-20 |
| Lightning Node | $0 (self-hosted) or VPS cost |
| **Total** | **Under $200/month** |

Break-even at a few hundred paying users.

---

## Next Steps

- [Payment Flow Details](PAYMENT_FLOW.md)
- [Getting Started Guide](../guides/GETTING_STARTED.md)
- [UPS & Graceful Shutdown](../guides/UPS_AND_GRACEFUL_SHUTDOWN.md) - Protect your node from power failures
