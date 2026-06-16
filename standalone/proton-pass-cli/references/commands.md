# Proton Pass CLI — Full Command Reference

Complete reference for every `pass-cli` subcommand and flag. Load this file when the user asks for exhaustive flag details or edge cases not covered in SKILL.md.

---

## Table of Contents
- [login / logout](#login--logout)
- [info / test / user / settings](#info--test--user--settings)
- [share](#share)
- [vault](#vault)
- [item](#item)
- [invite](#invite)
- [view / run / inject](#view--run--inject)
- [ssh-agent](#ssh-agent)
- [password](#password)
- [pat](#pat)
- [update / completions](#update--completions)

---

## login / logout

```
pass-cli login
pass-cli login --interactive [USERNAME]
pass-cli login --personal-access-token TOKEN

Flags:
  --interactive          Use CLI-based auth (username/password)
  --personal-access-token TOKEN   Authenticate with a PAT

Auth env vars:
  PROTON_PASS_PASSWORD             Account password
  PROTON_PASS_PASSWORD_FILE        Path to file containing password
  PROTON_PASS_TOTP                 TOTP code
  PROTON_PASS_TOTP_FILE            Path to file containing TOTP
  PROTON_PASS_EXTRA_PASSWORD       Extra Pass password
  PROTON_PASS_EXTRA_PASSWORD_FILE  Path to file with extra password
  PROTON_PASS_PERSONAL_ACCESS_TOKEN  PAT token string

pass-cli logout
```

---

## info / test / user / settings

```
pass-cli info              # Show account, session, plan info
pass-cli test              # Verify session is active and valid

pass-cli user info         # Detailed user account data

pass-cli settings list
pass-cli settings set default-vault VAULT_NAME
pass-cli settings set default-format (human|json)
pass-cli settings get default-vault
pass-cli settings get default-format
pass-cli settings unset default-vault
pass-cli settings unset default-format
```

---

## share

The `share` command manages access to shared vaults and items at a lower level than `vault share`.

```
pass-cli share list [--output FORMAT]
pass-cli share get (--share-id ID | --vault-name NAME) [--output FORMAT]
```

---

## vault

```
pass-cli vault list [--output FORMAT]

pass-cli vault create --name NAME

pass-cli vault update (--share-id ID | --vault-name NAME) --name NEW_NAME

pass-cli vault delete (--share-id ID | --vault-name NAME)

pass-cli vault share (--share-id ID | --vault-name NAME) EMAIL [--role ROLE]
  Roles: viewer | editor | manager (default: viewer)

pass-cli vault member list (--share-id ID | --vault-name NAME) [--output FORMAT]
pass-cli vault member update (--share-id ID | --vault-name NAME) \
  --member-share-id MEMBER_ID --role ROLE
pass-cli vault member remove (--share-id ID | --vault-name NAME) \
  --member-share-id MEMBER_ID

pass-cli vault transfer (--share-id ID | --vault-name NAME) MEMBER_SHARE_ID
```

---

## item

### list
```
pass-cli item list [VAULT_NAME] [--share-id ID] [--output FORMAT]
```

### create login
```
pass-cli item create login \
  (--share-id ID | --vault-name NAME) \
  --title TITLE \
  [--username USERNAME] \
  [--email EMAIL] \
  [--password PASSWORD] \
  [--generate-password[=LENGTH,uppercase,symbols,numbers]] \
  [--generate-passphrase[=WORD_COUNT]] \
  [--url URL]... \
  [--from-template FILE | -]
  [--get-template]
  [--totp TOTP_URI]
```

### create ssh-key generate
```
pass-cli item create ssh-key generate \
  (--share-id ID | --vault-name NAME) \
  --title TITLE \
  [--key-type ed25519|rsa2048|rsa4096] \
  [--comment COMMENT] \
  [--password]

SSH key env vars:
  PROTON_PASS_SSH_KEY_PASSWORD       Passphrase as plain text
  PROTON_PASS_SSH_KEY_PASSWORD_FILE  Path to file with passphrase
```

### create ssh-key import
```
pass-cli item create ssh-key import \
  (--share-id ID | --vault-name NAME) \
  --title TITLE \
  --private-key-file PATH \
  [--passphrase PASSPHRASE]
```

### view
```
pass-cli item view \
  (--share-id ID | --vault-name NAME) \
  (--item-id ID | --item-title TITLE) \
  [--output FORMAT]
```

### update
```
pass-cli item update \
  (--share-id ID | --vault-name NAME) \
  (--item-id ID | --item-title TITLE) \
  [--title NEW_TITLE] \
  [--username USERNAME] \
  [--email EMAIL] \
  [--password PASSWORD] \
  [--url URL]... \
  [--custom-field "KEY=VALUE"]...
```

### delete
```
pass-cli item delete \
  (--share-id ID | --vault-name NAME) \
  (--item-id ID | --item-title TITLE)
```

### share
```
pass-cli item share \
  (--share-id ID | --vault-name NAME) \
  (--item-id ID | --item-title TITLE) \
  EMAIL [--role ROLE]
```

### attachment
```
pass-cli item attachment download \
  (--share-id ID | --vault-name NAME) \
  (--item-id ID | --item-title TITLE) \
  [--attachment-id ID] \
  [--output PATH]
```

### alias
```
pass-cli item alias create \
  (--share-id ID | --vault-name NAME) \
  --title TITLE \
  [--note NOTE]
```

---

## invite

```
pass-cli invite list [--output FORMAT]
pass-cli invite accept --invite-token TOKEN
pass-cli invite reject --invite-token TOKEN
```

---

## view / run / inject

### view
```
pass-cli view pass://vault/item/field
pass-cli view --vault-name VAULT --item-title ITEM --field FIELD
```

### run
```
pass-cli run [--env-file FILE]... [--no-masking] -- COMMAND [ARGS...]

Options:
  --env-file FILE    Load env vars from a dotenv file (repeatable)
  --no-masking       Don't mask secret values in stdout/stderr

Secret reference format in env:
  MY_VAR=pass://vault-name/item-title/field-name
```

### inject
```
pass-cli inject [--in-file FILE] [--out-file FILE] [--force] [--file-mode MODE]

Options:
  --in-file, -i FILE    Template input (default: stdin)
  --out-file, -o FILE   Output file (default: stdout)
  --force               Overwrite output file if it exists
  --file-mode MODE      Permissions for output file (e.g. 0600)

Template syntax: {{ pass://vault/item/field }}
Note: run uses bare pass:// URIs; inject requires {{ }} wrapping
```

---

## ssh-agent

```
pass-cli ssh-agent start \
  (--share-id ID | --vault-name NAME) \
  [--socket-path PATH] \
  [--refresh-interval SECONDS] \
  [--create-new-identities (VAULT_NAME | SHARE_ID)]

pass-cli ssh-agent load \
  (--share-id ID | --vault-name NAME)

pass-cli ssh-agent debug \
  (--share-id ID | --vault-name NAME) \
  [--item-id ID | --item-title TITLE]

pass-cli ssh-agent daemon start
pass-cli ssh-agent daemon stop
```

After starting, set:
```bash
export SSH_AUTH_SOCK=/path/to/proton-pass-agent.sock
```

---

## password

```
pass-cli password generate random \
  [--length N] \
  [--uppercase true|false] \
  [--numbers true|false] \
  [--symbols true|false]

pass-cli password generate passphrase \
  [--count N] \
  [--separator hyphens|spaces|numbers|none] \
  [--capitalize true|false] \
  [--numbers true|false]

pass-cli password score PASSWORD [--output human|json]
```

---

## pat

```
pass-cli pat list [--output FORMAT]

pass-cli pat create \
  --name NAME \
  [--expires-in DAYS]

pass-cli pat grant \
  --token-id ID \
  (--vault-name NAME | --share-id ID)

pass-cli pat revoke --token-id ID

pass-cli pat delete --token-id ID
```

---

## update / completions

```
pass-cli update                    # Update to latest
pass-cli update --set-track stable # Switch to stable channel
pass-cli update --set-track beta   # Switch to beta channel

pass-cli completions bash
pass-cli completions zsh
pass-cli completions fish
```
