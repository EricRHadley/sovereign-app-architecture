# Payment Flow Architecture

## Overview

Two primary payment flows:
1. **Tipping** - Simple one-way payment, no access control
2. **Unlocking** - Payment grants time-limited or permanent access

Both use the same underlying infrastructure but differ in what happens after payment.

---

## Tipping Flow

```
┌──────────────────────────────────────────────────────────────┐
│                         TIPPING FLOW                         │
└──────────────────────────────────────────────────────────────┘

1. User Action
   └── User clicks "Tip" button, selects amount

2. Invoice Generation
   └── Frontend calls /api/tips
   └── Server requests invoice from BTCPay
   └── BTCPay asks LND to create Lightning invoice

3. QR Display
   └── BTCPay returns invoice + QR code
   └── User sees QR in modal

4. Payment
   └── User scans QR with Lightning wallet
   └── Payment routes through Lightning Network
   └── LND receives payment

5. Settlement
   └── BTCPay detects payment via LND
   └── Webhook fires to your server
   └── Server updates tip statistics

6. Confirmation
   └── Frontend shows success message
   └── Tip count updates on page
```

**Time to complete**: Typically seconds (Lightning settlement)

---

## Unlock Flow

```
┌──────────────────────────────────────────────────────────────┐
│                        UNLOCK FLOW                           │
└──────────────────────────────────────────────────────────────┘

1. User Action
   └── User clicks locked video
   └── Unlock modal shows pricing options

2. Invoice Generation
   └── Frontend calls /api/unlock/create-invoice
   └── Server requests invoice from BTCPay
   └── Returns invoice + checkout link

3. QR Display
   └── User sees QR code (Lightning) or address (on-chain)
   └── Amount shown in sats

4. Payment
   └── User pays from any Lightning wallet
   └── Payment routes to your node

5. Webhook Processing
   └── BTCPay webhook fires on settlement
   └── Server verifies payment amount matches tier
   └── Server generates cryptographic token

6. Token Delivery
   └── Token returned to frontend
   └── Stored in browser localStorage
   └── Contains: videoId, tier, expiration, signature

7. Access Granted
   └── Video player requests segments
   └── Token included in requests
   └── Server validates signature
   └── Segments served if valid
```

---

## Token Architecture

### How It Works

Tokens are cryptographically signed data structures containing:
- **Video identifier** - Which video this token unlocks
- **Access tier** - 24-hour or forever
- **Expiration** - When the token expires (null for forever)
- **Signature** - HMAC-SHA256 proof the server issued this token

### Why Stateless Tokens?

1. **No database lookups** - Validation is pure math
2. **Infinite scalability** - No session storage bottleneck
3. **Portable** - User can backup and restore tokens
4. **Privacy** - Server doesn't track who has access

### Implementation Approach

Rather than copying code snippets that may become outdated, we recommend:

1. **Point your AI assistant at the BTCPay documentation** for webhook handling
2. **Describe what you want** - "I need to verify a BTCPay webhook signature"
3. **Iterate together** - Let the AI read the current docs and generate appropriate code
4. **Test thoroughly** - Verify the implementation works with your specific setup

This approach ensures you get code that matches current API versions and your specific architecture.

---

## HLS Video Protection

### The Challenge

HLS (HTTP Live Streaming) breaks video into small segments (~6 seconds each).
Each segment is a separate HTTP request.
How do you protect thousands of segment requests efficiently?

### The Solution

1. **Route all segment requests through authentication middleware**
2. **Validate the token on each request** (HMAC verification is fast)
3. **Serve the segment if valid**, return 403 if not

The token rides along with segment requests. Your middleware validates the signature, checks expiration, and serves or denies accordingly.

### Platform Considerations

- **Desktop browsers**: Token can be passed as query parameter
- **iOS Safari**: Requires special handling (cookies) because the native HLS player strips query parameters
- **Mobile browsers**: Test thoroughly - behavior varies

---

## Pricing Tiers

| Tier | Price | Duration | Use Case |
|------|-------|----------|----------|
| 24-hour | 100 sats (~$0.10) | 24 hours | Impulse view |
| Forever | 3,000 sats (~$3.00) | Permanent | Collectors |
| Streaming | 1 sat/segment | Pay-per-view | Future option |

Pricing is configurable per video or globally.

---

## BTCPay Webhooks

### What Happens

When payment settles, BTCPay sends a webhook to your server containing:
- Invoice ID
- Payment status
- Your custom metadata (video ID, tier, etc.)

### Your Server's Job

1. **Verify the webhook signature** (see BTCPay docs for current format)
2. **Look up the invoice** to confirm payment details
3. **Generate the unlock token**
4. **Return it to the waiting frontend**

### Important: Use Current Documentation

BTCPay's webhook format and signature verification method may change between versions. Always refer to:
- [BTCPay Webhook Documentation](https://docs.btcpayserver.org/Development/GreenFieldExample/#webhooks)
- [BTCPay API Reference](https://docs.btcpayserver.org/API/Greenfield/v1/)

---

## Error Handling

### Payment Timeouts

Lightning invoices expire (typically 15-60 minutes).
Frontend polls for payment status and shows expiration.
User can request new invoice if expired.

### Webhook Failures

BTCPay retries webhooks with exponential backoff.
Implement idempotency - same invoice shouldn't generate multiple tokens.

### Token Expiration

24-hour tokens expire gracefully.
Video stops playing mid-stream if token expires.
User prompted to purchase again.

---

## Security Principles

### Webhook Validation

Always verify webhook signatures before trusting the payload. The specific implementation depends on your BTCPay version - consult current documentation.

### Rate Limiting

Protect your endpoints:
- **Invoice creation**: Prevent spam that fills your BTCPay database
- **Token validation**: Prevent brute force attempts

### Key Management

- Store signing keys in environment variables
- Never commit keys to git
- Rotate keys periodically (with migration support for existing tokens)
- Backup keys securely (encrypted)

---

## Next Steps

- [Getting Started Guide](../guides/GETTING_STARTED.md)
- [BTCPay Setup](../guides/BTCPAY_SETUP.md)
