# Proton Pass CLI — CI/CD & Automation Patterns

Load this file when the user wants to integrate Proton Pass CLI into pipelines, scripts, Docker, or automated workflows.

---

## GitHub Actions

### Basic secret injection
```yaml
name: Deploy

on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Proton Pass CLI
        run: curl -fsSL https://proton.me/download/pass-cli/install.sh | bash

      - name: Authenticate with PAT
        env:
          PROTON_PASS_PERSONAL_ACCESS_TOKEN: ${{ secrets.PROTON_PASS_PAT }}
        run: pass-cli login

      - name: Run deploy with injected secrets
        run: |
          pass-cli run \
            --env-file .env.production \
            -- ./deploy.sh

      - name: Generate config from template
        run: |
          pass-cli inject \
            --in-file config.yaml.template \
            --out-file config.yaml \
            --file-mode 0600
```

### Using secrets across multiple steps
```yaml
      - name: Export secrets to env
        run: |
          # Use run to export secrets inline
          DB_PASS=$(pass-cli view pass://Production/Database/password)
          echo "::add-mask::$DB_PASS"
          echo "DB_PASS=$DB_PASS" >> $GITHUB_ENV
```

---

## GitLab CI/CD

```yaml
stages:
  - deploy

deploy:
  stage: deploy
  before_script:
    - curl -fsSL https://proton.me/download/pass-cli/install.sh | bash
    - PROTON_PASS_PERSONAL_ACCESS_TOKEN="$PROTON_PASS_PAT" pass-cli login
  script:
    - pass-cli run --env-file .env.production -- ./deploy.sh
  variables:
    PROTON_PASS_PAT: $PROTON_PASS_PAT   # Set in GitLab CI variables
```

---

## Docker

### In Dockerfile
```dockerfile
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y curl bash

# Install pass-cli
RUN curl -fsSL https://proton.me/download/pass-cli/install.sh | bash

COPY . /app
WORKDIR /app

# Auth happens at runtime, not build time
CMD ["pass-cli", "run", "--env-file", ".env.production", "--", "./server"]
```

### docker-compose with PAT
```yaml
services:
  app:
    build: .
    environment:
      PROTON_PASS_PERSONAL_ACCESS_TOKEN: "${PROTON_PASS_PAT}"
    command: >
      sh -c "pass-cli login &&
             pass-cli run --env-file .env.production -- ./server"
```

### Multi-stage build (secrets only at runtime)
```dockerfile
# Build stage — no secrets
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Runtime stage
FROM node:20-alpine
RUN apk add --no-cache curl bash
RUN curl -fsSL https://proton.me/download/pass-cli/install.sh | bash

WORKDIR /app
COPY --from=builder /app/dist ./dist

# Use entrypoint to inject secrets at container start
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```

```bash
#!/bin/sh
# entrypoint.sh
pass-cli login
exec pass-cli run --env-file .env.production -- node dist/server.js
```

---

## Kubernetes

### As an init container
```yaml
apiVersion: v1
kind: Pod
spec:
  initContainers:
    - name: inject-secrets
      image: ubuntu:24.04
      env:
        - name: PROTON_PASS_PERSONAL_ACCESS_TOKEN
          valueFrom:
            secretKeyRef:
              name: proton-pat
              key: token
      command:
        - sh
        - -c
        - |
          curl -fsSL https://proton.me/download/pass-cli/install.sh | bash
          pass-cli login
          pass-cli inject \
            --in-file /config-templates/app.yaml \
            --out-file /config/app.yaml \
            --file-mode 0600
      volumeMounts:
        - name: config-templates
          mountPath: /config-templates
        - name: config
          mountPath: /config
  containers:
    - name: app
      image: myapp:latest
      volumeMounts:
        - name: config
          mountPath: /config
```

---

## Bash Scripting Patterns

### Secure login script
```bash
#!/bin/bash
set -euo pipefail

# Load credentials from secure files
export PROTON_PASS_PASSWORD_FILE="${HOME}/.proton/password"
export PROTON_PASS_TOTP_FILE="${HOME}/.proton/totp"

# Login
pass-cli login --interactive user@proton.me

# Verify
pass-cli test || { echo "Session invalid after login"; exit 1; }
```

### Database backup with injected credentials
```bash
#!/bin/bash
set -euo pipefail

# Inject DB credentials and run backup
pass-cli run \
  --env-file .env.production \
  -- bash -c '
    pg_dump \
      --host="$DB_HOST" \
      --username="$DB_USER" \
      --dbname="$DB_NAME" \
      > backup_$(date +%Y%m%d).sql
  '
```

### Rotate a secret
```bash
#!/bin/bash
# Generate a new password and update item
NEW_PASS=$(pass-cli password generate random --length 20 --uppercase true --symbols true)

pass-cli item update \
  --vault-name "Production" \
  --item-title "Database" \
  --password "$NEW_PASS"

echo "Password rotated successfully"
```

### Bulk item creation from CSV
```bash
#!/bin/bash
# CSV format: title,username,password,url

while IFS=',' read -r title username password url; do
  echo "Creating item: $title"
  pass-cli item create login \
    --vault-name "Imported" \
    --title "$title" \
    --username "$username" \
    --password "$password" \
    --url "$url"
done < credentials.csv
```

---

## .env File Patterns

### Development `.env.development`
```env
# Plain values for local dev
DB_HOST=localhost
DB_PORT=5432
DB_USER=devuser
DB_PASSWORD=devpassword
API_KEY=dev_key_123
```

### Production `.env.production` (with secret references)
```env
# Secret references resolved by pass-cli
DB_HOST=prod-db.internal
DB_PORT=5432
DB_USER=pass://Production/Database/username
DB_PASSWORD=pass://Production/Database/password
API_KEY=pass://Production/ExternalAPI/api_key
STRIPE_SECRET=pass://Production/Stripe/secret_key
```

---

## Cron Jobs

```bash
# crontab -e
# Daily backup at 2am with Proton Pass secrets
0 2 * * * /usr/local/bin/pass-cli run --env-file /etc/app/.env.production -- /opt/scripts/backup.sh >> /var/log/backup.log 2>&1
```

---

## Headless / Server Environments

When no browser or keyring is available, set the encryption key:

```bash
# Generate once and store securely
ENCRYPTION_KEY=$(dd if=/dev/urandom bs=1 count=2048 2>/dev/null | sha256sum | awk '{print $1}')

# Store in a secret manager or secure vault
echo "$ENCRYPTION_KEY" > /etc/proton-pass/encryption.key
chmod 600 /etc/proton-pass/encryption.key

# Set in environment before running pass-cli
export PROTON_PASS_ENCRYPTION_KEY="$(cat /etc/proton-pass/encryption.key)"
export PROTON_PASS_PERSONAL_ACCESS_TOKEN="pst_xxxx::TOKENKEY"
pass-cli login
```

---

## Security Best Practices for CI/CD

1. **Use PATs, not full account credentials** — Create a PAT with access only to required vaults
2. **Rotate PATs regularly** — Use `--expires-in DAYS` when creating
3. **Never log secrets** — `pass-cli run` masks secrets by default; avoid `--no-masking`
4. **Set file permissions** — Use `--file-mode 0600` with `inject`
5. **Clear env vars after use** — `unset PROTON_PASS_PASSWORD` after login
6. **Audit vault access** — Regularly review `pass-cli vault member list`
7. **Least privilege** — Grant PATs viewer access when write isn't needed
