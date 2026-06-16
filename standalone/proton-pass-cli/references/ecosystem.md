# Proton Ecosystem — Full Product Reference

Load this file when the user asks about Proton products beyond Pass CLI, or about their Proton account/subscription.

---

## Proton Account

One Proton account gives access to all Proton services. Plans:

| Plan | Services | Price (approx) |
|------|---------|---------------|
| **Free** | Mail (1GB), VPN (limited), Calendar, Drive (1GB) | Free |
| **Pass Free** | Pass (limited vaults/items) | Free |
| **Pass Plus** | Pass (unlimited), pass-cli | ~$4.99/mo |
| **Pass Family** | Pass Plus for 6 users | ~$3.99/user/mo |
| **Pass Pro** | Pass + team features | Business pricing |
| **Proton Unlimited** | All services (Mail, VPN, Drive, Calendar, Pass) | ~$9.99/mo |
| **Proton Duo** | Unlimited for 2 | ~$14.99/mo |
| **Proton Family** | Unlimited for 6 | ~$29.99/mo |
| **Proton Business** | All services, team management | Business pricing |

All Proton services use **end-to-end encryption (E2EE)** — Proton cannot read your data.

---

## Proton Pass

**What it is:** Password manager and secrets management tool.

**Key features:**
- Encrypted vaults for logins, notes, credit cards, identities, SSH keys
- SimpleLogin integration for email aliasing
- Pass Monitor (dark web monitoring, weak password detection)
- `pass-cli` for terminal and automation use
- Browser extensions (Chrome, Firefox, Safari, Brave, Edge)
- Mobile apps (iOS, Android)
- Import from 1Password, Bitwarden, LastPass, Dashlane, Keeper, etc.

**CLI availability:** Pass Plus, Pass Family, Pass Pro, all Proton bundles.

**Docs:** https://protonpass.github.io/pass-cli/ | https://proton.me/pass

---

## Proton Mail

**What it is:** Encrypted email service.

**Key features:**
- End-to-end encrypted email (PGP-based)
- Zero-access encryption (Proton can't read your mail)
- Custom domains (paid plans)
- Aliases and + addressing
- Bridge app for desktop email clients (Outlook, Thunderbird, Apple Mail)
- Proton Sentinel (advanced account protection)
- Filters and folders
- Self-destructing messages

**CLI:** No official CLI. The **Proton Mail Bridge** enables IMAP/SMTP access for desktop clients.

**Bridge download:** https://proton.me/mail/bridge

**API:** https://proton.me/blog/proton-mail-api (limited public API)

**Docs:** https://proton.me/support/mail

---

## ProtonVPN

**What it is:** Privacy-focused VPN with no-log policy.

**Key features:**
- No-logs policy (independently audited)
- Servers in 90+ countries
- NetShield (ad/tracker/malware blocker)
- Secure Core (route through hardened servers)
- VPN Accelerator
- Kill switch
- Split tunneling
- Tor over VPN
- P2P / torrenting support on many servers
- Free tier (3 server locations, 1 device)

**CLI (Linux):**
```bash
# Install
sudo apt install protonvpn-cli   # or via official repo

# Login
protonvpn-cli login USERNAME

# Connect
protonvpn-cli connect             # Auto-select server
protonvpn-cli connect --fastest   # Fastest available
protonvpn-cli connect --cc US     # Connect to US server
protonvpn-cli connect --sc        # Secure Core

# Disconnect
protonvpn-cli disconnect

# Status
protonvpn-cli status
```

**Linux GUI:** ProtonVPN app available as .deb, .rpm, or AppImage.

**Docs:** https://proton.me/support/linux-vpn-tool

---

## Proton Drive

**What it is:** Encrypted cloud storage.

**Key features:**
- End-to-end encrypted file storage
- File sharing with E2EE links
- Automatic photo backup (mobile)
- Computer backup (desktop app)
- Revision history
- 1GB free, up to 3TB on paid plans

**CLI:** No official CLI at this time. Available via:
- Web: https://drive.proton.me
- Desktop apps (Windows, macOS, Linux)
- Mobile apps (iOS, Android)

**Docs:** https://proton.me/support/drive

---

## Proton Calendar

**What it is:** Encrypted calendar service.

**Key features:**
- End-to-end encrypted events (Proton can't see your calendar)
- Shared calendars
- Import/export ICS
- Invites via ProtonMail
- Integrated with ProtonMail

**CLI:** No official CLI. Available via:
- Web: https://calendar.proton.me
- Mobile apps (iOS, Android, Proton Mail app)

**Docs:** https://proton.me/support/calendar

---

## SimpleLogin (Email Aliasing)

**What it is:** Email alias service, integrated with Proton Pass.

**Key features:**
- Create unlimited email aliases
- Aliases forward to your real inbox
- Reply from aliases (hides real email)
- Custom domains
- Browser extension
- Integrated directly into Proton Pass for alias creation

**CLI / API:**
```bash
# SimpleLogin API (requires API key from app.simplelogin.io)
curl -H "Authentication: YOUR_API_KEY" \
  https://app.simplelogin.io/api/aliases

# Create alias via API
curl -X POST \
  -H "Authentication: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"alias_prefix": "shopping", "signed_suffix": "...", "mailbox_ids": [1]}' \
  https://app.simplelogin.io/api/v3/alias/custom/new
```

**Docs:** https://simplelogin.io/docs/ | https://proton.me/pass/aliases

---

## Proton Sentinel

**What it is:** Advanced account protection (included in Proton Unlimited+).

- Real-time monitoring of login attempts
- Manual review of suspicious logins by Proton security team
- Immediate blocking of suspicious sessions
- Available for all Proton services

**Enable in:** Account settings → Security → Proton Sentinel

---

## Proton Pass Monitor

**What it is:** Security monitoring built into Proton Pass.

- Dark web monitoring — alerts if your email/passwords appear in breaches
- Weak password detection
- Reused password detection
- Missing 2FA alerts
- Inactive 2FA detection

**Access:** Via Proton Pass app or browser extension → Pass Monitor tab.

---

## Account Security Tips

1. **Enable 2FA** on your Proton account (Settings → Security → Two-Factor Authentication)
2. **Enable Proton Sentinel** for enhanced protection (Proton Unlimited+)
3. **Use a hardware key** (YubiKey, etc.) as 2FA — only supported via web login in pass-cli
4. **Create a recovery phrase** — required if you lose 2FA access
5. **Use PATs for automation** — never use your main account credentials in scripts
6. **Review connected devices** regularly (Settings → Security → Active sessions)

---

## Proton Links

| Resource | URL |
|----------|-----|
| Proton Account | https://account.proton.me |
| Proton Mail | https://mail.proton.me |
| ProtonVPN | https://protonvpn.com |
| Proton Drive | https://drive.proton.me |
| Proton Calendar | https://calendar.proton.me |
| Proton Pass | https://pass.proton.me |
| SimpleLogin | https://app.simplelogin.io |
| Pass CLI docs | https://protonpass.github.io/pass-cli/ |
| Proton Support | https://proton.me/support |
| Proton Blog | https://proton.me/blog |
| Proton Status | https://protonstatus.com |
| GitHub (Proton) | https://github.com/ProtonMail |
| GitHub (Pass CLI) | https://github.com/protonpass/pass-cli |
