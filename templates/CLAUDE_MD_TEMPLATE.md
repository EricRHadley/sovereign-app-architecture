# CLAUDE.md Template

This file tells your AI coding assistant about your project. Place it in your project root.

---

## Example CLAUDE.md

```markdown
# Project Name - AI Assistant Guide

## Project Overview

Brief description of what this project does.

## Project Structure

```
~/project-name/
├── frontend/          # HTML/CSS/JS
├── backend/           # Node.js API
├── scripts/           # Python utilities
└── docs/              # Documentation
```

## Critical Rules

### Never Do These

- Never edit files directly on production servers
- Never commit secrets or API keys to git
- Never run commands that transfer funds without explicit approval
- Never modify the database without creating a backup first

### Always Do These

- Always test changes locally before deploying
- Always commit changes with clear messages
- Always update cache-busting versions when modifying CSS/JS
- Always use the git workflow for deployment

### Why These Rules Exist (Document Past Incidents)

Rules without context get ignored. Document real incidents:

```markdown
**Database Overwrite Incident**: videos.json was tracked in git. Claude
edited local copy and pushed, overwriting all live production data.
→ RULE: Live data files (.json databases) must be in .gitignore
→ RULE: Use API endpoints or migration scripts to update live data
→ RULE: Never git push files that contain production state
```

Turn every mistake into a documented rule. Future sessions will understand why the rule exists.

## Plan Files & Context Management

AI assistants have limited context windows. Plan files are your external memory.

### Creating Plans
For complex tasks, create a plan file:
```
"Let's make a plan for setting up BTCPay. Write it to docs/btcpay-setup-plan.md"
```

### Resuming Work
When starting a new session:
```
"Read docs/btcpay-setup-plan.md and continue where we left off"
```

### What Goes in Plan Files
- Task breakdown and progress tracking
- Decisions made and why
- Issues encountered and solutions
- Next steps

Plan files survive context resets. They ARE your project memory.

## Development Workflow

1. Edit files locally in `~/project-name/`
2. Test changes locally
3. `git add . && git commit -m "Description"`
4. `git push origin master`
5. Deploy: `ssh server "cd /path/to/project && git pull"`

## Server Access

### Production Server
- Host: `production-server` (use SSH alias)
- User: `deploy`
- Web root: `/var/www/project/`

### What Claude Can Access
- Production web server (for deployment)

### What Claude Cannot Access
- Payment infrastructure (BTCPay, Lightning node)
- Database servers directly

### Lightning Node Safety (If Applicable)

If your project includes a Lightning node:

**NEVER do these:**
- Use `sudo` on the Lightning node - can corrupt wallet/database
- Run commands that transfer funds without explicit user approval
- Expose LND ports (8080, 10009) directly to the internet

**Safe commands (read-only):**
- `lncli getinfo`, `lncli listchannels`, `lncli walletbalance`
- `lncli listpeers`, `lncli pendingchannels`

**Dangerous commands (require explicit approval):**
- `lncli openchannel`, `lncli closechannel`
- `lncli sendpayment`, `lncli sendcoins`
- Any command with `--force` flags
- `loop out`, `loop in`

## Key Concepts

### Concept That Needs Clarification

Explain any domain-specific concepts that might be confusing.
For example, in Lightning:
- "Inbound capacity" = sats on the remote side of channels
- "Outbound capacity" = sats on your side (what you can send)

## File Locations

### Critical Files
- Main config: `backend/config.js`
- Database: `data/database.json`
- Secrets: Environment variables only (never in files)

### Files to Never Edit Directly
- `data/production.json` - live data, use migration scripts

## Deployment Checklist

- [ ] Changes tested locally
- [ ] Clear commit message written
- [ ] Pushed to git repository
- [ ] Cache-busting versions updated (if CSS/JS changed)
- [ ] Server git pull executed
- [ ] Services restarted if needed

## Common Commands

### Local Development
```bash
npm run dev           # Start development server
npm test              # Run tests
```

### Server Management
```bash
ssh production-server "pm2 status"
ssh production-server "pm2 restart app"
ssh production-server "pm2 logs app --lines 50"
```

## Troubleshooting

### Issue: Changes not appearing
- Check cache-busting versions in HTML
- Hard refresh browser (Ctrl+Shift+R)
- Verify git pull completed on server

### Issue: Service not starting
- Check logs: `pm2 logs app`
- Verify environment variables set
- Check file permissions

---

Last Updated: [Date]
```

---

## Key Sections Explained

### Critical Rules
The most important section. Document:
- What should never be done (especially things that could cause data loss)
- What should always be done (best practices that prevent issues)

### Server Access
Be explicit about what infrastructure Claude can and cannot access. Separation of concerns is key to security.

### Key Concepts
Clarify domain-specific terminology. AI assistants know a lot, but your specific project may use terms differently.

### Deployment Checklist
A checklist prevents forgotten steps. Make it comprehensive.

---

## Tips for Writing Effective CLAUDE.md

1. **Be specific about prohibitions** - Vague rules get violated
2. **Include real examples** - Show actual commands and paths
3. **Document past mistakes** - Turn incidents into rules
4. **Keep it updated** - Add new rules as you learn
5. **Include troubleshooting** - Common issues and fixes

---

## Adapting for Your Project

Replace:
- Project paths with your actual paths
- Server aliases with your aliases
- Concepts with your domain knowledge
- Commands with your actual commands

The goal: Anyone (human or AI) reading this file understands how to work on your project safely.
