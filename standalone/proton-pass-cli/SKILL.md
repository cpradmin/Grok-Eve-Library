---
name: proton-pass-cli
description: >
  Expert guidance for Proton Pass CLI and the broader Proton ecosystem (ProtonMail, ProtonVPN, Proton Drive, Proton Calendar). Use this skill any time the user mentions: pass-cli, proton pass, proton vault, proton secrets, proton SSH agent, PAT tokens, secret injection, pass:// URIs, proton mail, protonvpn, proton drive, proton account, or anything Proton-related. Covers installation, authentication, vault and item management, secret injection into scripts/CI-CD pipelines, SSH agent integration, Personal Access Tokens, password generation, and automation workflows. Trigger even for casual phrasing like "set up proton cli", "inject secrets from proton", "share my proton vault", or "proton pass in my pipeline".
---

# Proton Pass CLI & Ecosystem Skill

You are an expert on Proton Pass CLI and the Proton privacy ecosystem. Use this skill for all Proton-related questions.

## Table of Contents
1. [Quick Orientation](#1-quick-orientation)
2. [Installation](#2-installation)
3. [Authentication](#3-authentication)
4. [Vault Management](#4-vault-management)
5. [Item Management](#5-item-management)
6. [Secret Injection](#6-secret-injection)
7. [SSH Agent Integration](#7-ssh-agent-integration)
8. [Personal Access Tokens (PAT)](#8-personal-access-tokens)
9. [Password Generation](#9-password-generation)
10. [CI/CD & Automation](#10-cicd--automation)
11. [Settings & Configuration](#11-settings--configuration)
12. [Proton Ecosystem Overview](#12-proton-ecosystem-overview)
13. [Troubleshooting](#13-troubleshooting)

> **Reference files**: For deeper details, see `references/commands.md` (full command reference), `references/cicd-patterns.md` (automation recipes), and `references/ecosystem.md` (all Proton products).

---

## 1. Quick Orientation

Proton Pass CLI (`pass-cli`) is a command-line interface for managing encrypted vaults, items, and secrets. It requires a **Pass Plus, Pass Family, Pass Professional**, or any **Proton bundle** plan (free plans cannot use the CLI).

**Core concepts:**
- **Vault** — top-level container for items. Has a Share ID (unique identifier).
- **Item** — a secret stored in a vault: login, note, credit card, identity, SSH key, alias, WiFi, custom.
- **Secret reference** — a `pass://vault/item/field` URI pointing to a secret.
- **PAT** — Personal Access Token: scoped credential for automation (no full account login needed).

---

## 2. Installation

### Linux / macOS
```bash
curl -fsSL https://proton.me/download/pass-cli/install.sh | bash
```

### Windows (PowerShell)
```powershell
Invoke-WebRequest -Uri https://proton.me/download/pass-cli/install.ps1 -OutFile install.ps1
.\install.ps1
```

### Via Homebrew (macOS/Linux)
```bash
brew install protonpass/tap/pass-cli
```

### Verify installation
```bash
pass-cli --version
```

### Shell completion (optional but recommended)
```bash
# bash
pass-cli completions bash > ~/.local/share/bash-completion/completions/pass-cli

# zsh
pass-cli completions zsh > "${fpath[1]}/_pass-cli"

# fish
pass-cli completions fish > ~/.config/fish/completions/pass-cli.fish
```

### Update / switch tracks
```bash
pass-cli update                    # Update to latest stable
pass-cli update --set-track beta   # Switch to beta track
pass-cli update --set-track stable # Switch back to stable
```

---

## 3. Authentication

### Web login (recommended — supports SSO, hardware keys)
```bash
pass-cli login
# Opens a URL — complete auth in browser
```

### Interactive login
```bash
pass-cli login --interactive user@proton.me
# Prompts for: password → TOTP (if enabled) → extra password (if set)
```

### Login via environment variables (scripting)
```bash
export PROTON_PASS_PASSWORD='your-password'
export PROTON_PASS_TOTP='123456'
export PROTON_PASS_EXTRA_PASSWORD='extra-pass'   # If configured
pass-cli login --interactive user@proton.me
```

### Login via credential files (more secure)
```bash
echo 'your-password' > /secure/pass.txt && chmod 600 /secure/pass.txt
export PROTON_PASS_PASSWORD_FILE='/secure/pass.txt'
export PROTON_PASS_TOTP_FILE='/secure/totp.txt'
pass-cli login --interactive user@proton.me
```

### Personal Access Token login (best for CI/CD)
```bash
PROTON_PASS_PERSONAL_ACCESS_TOKEN="pst_xxxx::TOKENKEY" pass-cli login
# Or:
pass-cli login --personal-access-token "pst_xxxx::TOKENKEY"
```

### Check session / logout
```bash
pass-cli info       # Show account info and session status
pass-cli test       # Verify session is valid
pass-cli logout     # End session
```

---

## 4. Vault Management

```bash
# List all vaults
pass-cli vault list
pass-cli vault list --output json

# Create a vault
pass-cli vault create --name "Production Secrets"

# Rename a vault
pass-cli vault update --vault-name "Old Name" --name "New Name"

# Delete a vault (DESTRUCTIVE — deletes all items inside)
pass-cli vault delete --vault-name "Old Vault"

# Share a vault with a colleague
pass-cli vault share --vault-name "Team Vault" alice@company.com --role editor
# Roles: viewer | editor | manager

# List vault members
pass-cli vault member list --vault-name "Team Vault"

# Update member role
pass-cli vault member update --vault-name "Team Vault" --member-share-id "ID" --role viewer

# Remove a member
pass-cli vault member remove --vault-name "Team Vault" --member-share-id "ID"

# Transfer vault ownership
pass-cli vault transfer --vault-name "My Vault" "member_share_id"
```

**Share roles:**
| Role | Permissions |
|------|------------|
| `viewer` | Read-only |
| `editor` | Read + write items |
| `manager` | Full control incl. sharing |

---

## 5. Item Management

### List items
```bash
pass-cli item list "VaultName"
pass-cli item list --share-id "abc123" --output json
pass-cli item list   # Uses default vault if configured
```

### Create a login item
```bash
pass-cli item create login \
  --vault-name "Personal" \
  --title "GitHub" \
  --username "myuser" \
  --password "mypassword" \
  --url "https://github.com"

# With auto-generated password
pass-cli item create login \
  --vault-name "Work" \
  --title "AWS Console" \
  --username "admin" \
  --generate-password="20,uppercase,symbols" \
  --url "https://console.aws.amazon.com"
```

### View an item
```bash
pass-cli item view --vault-name "Personal" --item-title "GitHub"
pass-cli item view --vault-name "Personal" --item-title "GitHub" --output json
```

### Update an item
```bash
# Update a single field
pass-cli item update --vault-name "Personal" --item-title "GitHub" --password "newpassword"

# Update title
pass-cli item update --vault-name "Personal" --item-title "GitHub" --title "GitHub (Work)"

# Add/update a URL
pass-cli item update --vault-name "Personal" --item-title "GitHub" --url "https://github.com"

# Custom fields
pass-cli item update --vault-name "Personal" --item-title "GitHub" \
  --custom-field "API Token=ghp_xxxxx"
```

### Delete an item
```bash
pass-cli item delete --vault-name "Personal" --item-title "Old Account"
```

### Share an item
```bash
pass-cli item share --vault-name "Personal" --item-title "GitHub" alice@company.com
```

### Create an SSH key item
```bash
# Generate a new SSH key
pass-cli item create ssh-key generate \
  --vault-name "Dev Keys" \
  --title "GitHub Deploy Key" \
  --key-type ed25519 \
  --comment "my-github-key"

# Import existing key
pass-cli item create ssh-key import \
  --vault-name "Dev Keys" \
  --title "Server Key" \
  --private-key-file ~/.ssh/id_ed25519
```

### Attachments
```bash
pass-cli item attachment download \
  --vault-name "Personal" \
  --item-title "Important Doc" \
  --output ~/Downloads/doc.pdf
```

### Aliases (SimpleLogin integration)
```bash
pass-cli item alias create \
  --vault-name "Personal" \
  --title "Shopping Alias"
```

### Using templates (bulk creation)
```bash
# Get a template for a login item
pass-cli item create login --get-template > template.json

# Fill in the template, then create from it
pass-cli item create login --from-template template.json --vault-name "Work"

# Pipe from stdin
echo '{"title":"Test","username":"user","password":"pass","urls":["https://test.com"]}' | \
  pass-cli item create login --vault-name "Work" --from-template -
```

---

## 6. Secret Injection

The `pass://vault/item/field` URI syntax is the core of secret injection.

### Secret reference URI format
```
pass://vault-name/item-title/field-name
```
Examples:
```
pass://Production/Database/password
pass://Work/AWS/access_key_id
pass://Personal/GitHub/api_token
```

### `view` — read a secret value
```bash
pass-cli view pass://Production/Database/password
# Or using flags:
pass-cli view --vault-name Production --item-title Database --field password
```

### `run` — inject secrets into a command
```bash
# Set env var with secret reference, then run command
export DB_PASSWORD='pass://Production/Database/password'
pass-cli run -- ./my-app

# Inline with the command
DB_PASSWORD='pass://Production/Database/password' \
API_KEY='pass://Work/External API/api_key' \
pass-cli run -- node server.js

# Load from .env files
pass-cli run --env-file .env.production -- ./deploy.sh

# Multiple env files (later files override earlier)
pass-cli run \
  --env-file .env.base \
  --env-file .env.production \
  -- node server.js

# Disable output masking (careful — secrets appear in logs)
pass-cli run --no-masking -- ./debug-script.sh
```

**`.env` file with secret references:**
```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=admin
DB_PASSWORD=pass://Production/Database/password
API_KEY=pass://Work/External API/api_key
```

### `inject` — inject secrets into template files
```bash
# Template file uses {{ pass://... }} syntax
pass-cli inject --in-file config.yaml.template --out-file config.yaml

# With force overwrite
pass-cli inject --in-file config.yaml.template --out-file config.yaml --force

# Set file permissions on output
pass-cli inject --in-file template.txt --out-file config.txt --file-mode 0600

# From stdin to stdout
pass-cli inject << 'EOF'
{
  "database": {
    "password": "{{ pass://Production/Database/password }}"
  }
}
EOF
```

**Template file syntax (`config.yaml.template`):**
```yaml
database:
  host: localhost
  port: 5432
  username: {{ pass://Production/Database/username }}
  password: {{ pass://Production/Database/password }}
api:
  key: {{ pass://Work/API Keys/api_key }}
```

---

## 7. SSH Agent Integration

### Start as SSH agent
```bash
pass-cli ssh-agent start --vault-name MySshKeysVault
# Output shows socket path — export it:
export SSH_AUTH_SOCK=/Users/you/.ssh/proton-pass-agent.sock

# Custom socket path
pass-cli ssh-agent start --vault-name MySshKeysVault --socket-path /tmp/myagent.sock

# Auto-create new identities from ssh-add
pass-cli ssh-agent start --vault-name MySshKeysVault --create-new-identities

# Custom key refresh interval (seconds)
pass-cli ssh-agent start --vault-name MySshKeysVault --refresh-interval 7200
```

### Load keys into existing agent
```bash
pass-cli ssh-agent load --vault-name MySshKeysVault
```

### Debug / troubleshoot key detection
```bash
pass-cli ssh-agent debug --vault-name MySshKeysVault
pass-cli ssh-agent debug --vault-name MySshKeysVault --item-title "my-github-key"
```

### Auto-start on login

**Linux (systemd service):**
```ini
# ~/.config/systemd/user/proton-ssh-agent.service
[Unit]
Description=Proton Pass SSH Agent

[Service]
ExecStart=/usr/local/bin/pass-cli ssh-agent start --vault-name SshKeys
Restart=on-failure

[Install]
WantedBy=default.target
```
```bash
systemctl --user enable --now proton-ssh-agent
```

**macOS (launchd plist):**
```xml
<!-- ~/Library/LaunchAgents/com.proton.ssh-agent.plist -->
<plist version="1.0"><dict>
  <key>Label</key><string>com.proton.ssh-agent</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/local/bin/pass-cli</string>
    <string>ssh-agent</string><string>start</string>
    <string>--vault-name</string><string>SshKeys</string>
  </array>
  <key>RunAtLoad</key><true/>
</dict></plist>
```

---

## 8. Personal Access Tokens

PATs provide scoped, revocable credentials for automation without exposing your full account.

```bash
# Create a PAT
pass-cli pat create --name "CI Pipeline Token"

# Create with expiry (days)
pass-cli pat create --name "Temp Token" --expires-in 30

# List PATs
pass-cli pat list

# Grant vault access to a PAT
pass-cli pat grant --token-id "TOKEN_ID" --vault-name "Production"

# Revoke a PAT
pass-cli pat revoke --token-id "TOKEN_ID"

# Delete a PAT
pass-cli pat delete --token-id "TOKEN_ID"
```

**Use the token to login:**
```bash
PROTON_PASS_PERSONAL_ACCESS_TOKEN="pst_xxxx::TOKENKEY" pass-cli login
```

---

## 9. Password Generation

```bash
# Generate a random password (default settings)
pass-cli password generate random

# Custom length with all character types
pass-cli password generate random --length 20 --uppercase true --symbols true --numbers true

# No symbols (for systems that don't allow them)
pass-cli password generate random --length 16 --symbols false

# Generate a memorable passphrase
pass-cli password generate passphrase
pass-cli password generate passphrase --count 5 --separator hyphens
pass-cli password generate passphrase --count 4 --capitalize true --numbers true

# Score a password
pass-cli password score "MyPassword123!"
pass-cli password score "MyPassword123!" --output json
```

---

## 10. CI/CD & Automation

See `references/cicd-patterns.md` for detailed recipes. Key patterns:

### GitHub Actions
```yaml
- name: Login to Proton Pass
  env:
    PROTON_PASS_PERSONAL_ACCESS_TOKEN: ${{ secrets.PROTON_PASS_PAT }}
  run: pass-cli login

- name: Run deploy with secrets
  run: |
    pass-cli run \
      --env-file .env.production \
      -- ./deploy.sh
```

### Docker / containers
```dockerfile
RUN curl -fsSL https://proton.me/download/pass-cli/install.sh | bash
```
```bash
docker run -e PROTON_PASS_PERSONAL_ACCESS_TOKEN="pst_xxxx::KEY" \
  myimage pass-cli run -- ./app
```

### Encryption key for headless environments
```bash
# Generate encryption key (Linux/macOS)
dd if=/dev/urandom bs=1 count=2048 2>/dev/null | sha256sum | awk '{print $1}'
# Set as environment variable:
export PROTON_PASS_ENCRYPTION_KEY="your-generated-key"
```

---

## 11. Settings & Configuration

```bash
# View current settings
pass-cli settings list

# Set a default vault (avoids typing --vault-name every time)
pass-cli settings set default-vault "Personal"

# Set default output format
pass-cli settings set default-format json

# View account/session info
pass-cli info

# User account commands
pass-cli user info
```

**Environment variables for config:**
| Variable | Purpose |
|----------|---------|
| `PROTON_PASS_ENCRYPTION_KEY` | Encryption key for headless/server use |
| `PROTON_PASS_PERSONAL_ACCESS_TOKEN` | PAT for non-interactive auth |
| `PROTON_PASS_PASSWORD` | Account password (scripting) |
| `PROTON_PASS_TOTP` | TOTP code (scripting) |
| `PROTON_PASS_EXTRA_PASSWORD` | Pass-specific extra password |
| `PROTON_PASS_LOG_LEVEL` | Log verbosity |

---

## 12. Proton Ecosystem Overview

> For full details on each product, see `references/ecosystem.md`.

| Product | Purpose | CLI Available? |
|---------|---------|----------------|
| **Proton Pass** | Password manager & secrets | ✅ `pass-cli` |
| **Proton Mail** | Encrypted email | ❌ (web/app only) |
| **ProtonVPN** | VPN | ✅ `protonvpn-cli` |
| **Proton Drive** | Encrypted cloud storage | ❌ (web/app only) |
| **Proton Calendar** | Encrypted calendar | ❌ (web/app only) |
| **SimpleLogin** | Email aliasing (integrated with Pass) | ✅ (API) |

All Proton products share a single Proton Account with end-to-end encryption (E2EE). One subscription (Proton Unlimited / Duo / Family) covers all services.

---

## 13. Troubleshooting

```bash
# Test if session is valid
pass-cli test

# Check version
pass-cli --version

# Verbose output
PROTON_PASS_LOG_LEVEL=debug pass-cli vault list

# Verify binary integrity
sha256sum pass-cli   # Compare against hash in Proton's versions file
```

**Common issues:**
| Problem | Solution |
|---------|---------|
| "CLI not available on free plan" | Upgrade to Pass Plus or a Proton bundle |
| Login fails with TOTP | TOTP codes expire in 30s — regenerate and retry quickly |
| Session expired | Run `pass-cli login` again |
| SSH keys not detected | Run `pass-cli ssh-agent debug --vault-name <name>` |
| Command not found after install | Ensure `~/.local/bin` or `/usr/local/bin` is in `$PATH` |
| PAT has no vault access | Use `pass-cli pat grant` to grant vault permissions |
| `inject` output file exists | Add `--force` flag to overwrite |

For support: https://proton.me/support/contact
Full docs: https://protonpass.github.io/pass-cli/
