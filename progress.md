# Progress Log

This file is the working reference for the Forem on Hostinger Arabic deployment.

Last updated: 2026-05-04 21:17:02 CDT

## Project Goal

Deploy Forem on an existing Hostinger VPS at:

```text
https://club.bannaa.ai
```

and later replace the temporary upstream image with a custom Arabic-enabled Forem image that remains easy to update from upstream Forem.

## Key Decisions

- Hosting provider: Hostinger VPS.
- VPS plan: KVM 1.
- VPS OS: Ubuntu 24.04.4 LTS.
- Keep existing Hostinger Traefik/OpenClaw stack: yes.
- Use Docker Compose for Forem, not a second Traefik.
- Keep Forem as a separate Docker Compose project next to existing Hostinger Docker projects.
- Use Resend for transactional email.
- Domain: `club.bannaa.ai`.
- Community name: `Bannaa`.
- Arabic support will be added in a future custom image rather than patched directly on the VPS.

## Local Files Added Or Updated

Planning and status:

```text
FOREM_HOSTINGER_ARABIC_PLAN.md
progress.md
deploy/README.md
deploy/FILL_VALUES_HERE.md
deploy/REQUIRED_FROM_USER.md
deploy/VPS_STATUS.md
deploy/TRAEFIK_NOTES.md
```

Deployment templates:

```text
deploy/compose.yml.example
deploy/config/forem.env
deploy/config/forem.env.example
deploy/config/Caddyfile.example
```

Scripts:

```text
deploy/scripts/inventory.sh
deploy/scripts/bootstrap-ubuntu.sh
deploy/scripts/bootstrap-fedora.sh
deploy/scripts/backup-postgres.sh
deploy/scripts/update-image.sh
deploy/scripts/install-units.sh
```

SSH/secrets:

```text
deploy/ssh/forem_hostinger_bsocial.pub
deploy/secrets/README.md
deploy/secrets/ssh-access.env
deploy/secrets/ssh-access.env.example
```

Ignore rules:

```text
.gitignore
```

Important `.gitignore` rules:

```text
deploy/config/forem.env
*.env
deploy/secrets/*
!deploy/secrets/*.example
!deploy/secrets/README.md
deploy/ssh/*
!deploy/ssh/*.pub
```

## SSH Access

A project-specific SSH key was generated locally:

```text
Private key: ~/.ssh/forem_hostinger_bsocial
Public key: deploy/ssh/forem_hostinger_bsocial.pub
```

The public key was installed on the VPS root account.

The root password was used once to install key access. After that, key-based SSH worked.

Local root-password file:

```text
deploy/secrets/ssh-access.env
```

Security state:

```text
deploy/secrets/: mode 700
deploy/secrets/ssh-access.env: mode 600
deploy/secrets/* ignored by git except README and .example files
```

TODO: remove or rotate the root password after setup is fully stable.

## VPS Inventory

Observed VPS state:

```text
Hostname: wasimo
Public IPv4: 31.97.6.123
OS: Ubuntu 24.04.4 LTS
CPU: 1 vCPU
Memory: about 3.8 GiB
Swap: none
Disk: 50 GB total, about 40 GB free before Forem image pulls
Docker: installed and running
Docker Compose: installed
Podman: not installed
```

Existing containers before Forem:

```text
traefik-traefik-1
openclaw-e2dq-openclaw-1
```

Ports already in use:

```text
80/tcp: Traefik
443/tcp: Traefik
46143/tcp: OpenClaw
22/tcp: SSH
```

## Existing Traefik

Traefik details:

```text
Compose path: /docker/traefik/docker-compose.yml
Container: traefik-traefik-1
Image: traefik:latest
Network mode: host
Docker provider: enabled
exposedByDefault: false
HTTP entrypoint: :80
HTTPS entrypoint: :443
Certificate resolver: letsencrypt
ACME storage: /letsencrypt/acme.json
```

OpenClaw is exposed with Docker labels, so Forem uses the same approach.

Forem web labels:

```yaml
traefik.enable=true
traefik.http.routers.forem.rule=Host(`club.bannaa.ai`)
traefik.http.routers.forem.entrypoints=websecure
traefik.http.routers.forem.tls.certresolver=letsencrypt
traefik.http.services.forem.loadbalancer.server.port=3000
```

## Remote Forem Layout

Remote files/directories created:

```text
/docker/forem/docker-compose.yml
/opt/forem/config/forem.env
/opt/forem/postgres
/opt/forem/redis
/opt/forem/uploads
/opt/forem/backups
/opt/forem/scripts
```

Permissions:

```text
/opt/forem/config/forem.env: mode 600
```

## Remote Env

Remote env path:

```text
/opt/forem/config/forem.env
```

Configured public values:

```env
APP_DOMAIN=club.bannaa.ai
APP_PROTOCOL=https://
DEFAULT_LOCALE=ar
COMMUNITY_NAME=Bannaa
DEFAULT_EMAIL=no-reply@club.bannaa.ai
SESSION_KEY=_club_bannaa_ai_session
SMTP_ADDRESS=smtp.resend.com
SMTP_PORT=587
SMTP_DOMAIN=club.bannaa.ai
SMTP_USER_NAME=resend
```

Generated directly on VPS:

```text
SECRET_KEY_BASE
FOREM_OWNER_SECRET
POSTGRES_PASSWORD
```

Set from user:

```text
SMTP_PASSWORD
```

Important: the Resend SMTP password/API key was pasted into chat. Rotate it later.

Current temporary image:

```env
FOREM_IMAGE=quay.io/forem/forem:latest
```

Final target image still needed:

```env
FOREM_IMAGE=ghcr.io/moeghashim/bannaa-club:production
```

## DNS And TLS

DNS record added by user:

```text
A club 31.97.6.123
```

Verified:

```text
club.bannaa.ai -> 31.97.6.123
```

Traefik issued a Let's Encrypt certificate:

```text
CN=club.bannaa.ai
Issuer: Let's Encrypt R13
```

## Current Running Containers

Forem Compose project:

```text
/docker/forem/docker-compose.yml
```

Running containers:

```text
forem-postgres-1
forem-redis-1
forem-web-1
forem-worker-1
```

Commands used:

```bash
cd /docker/forem
docker compose --env-file /opt/forem/config/forem.env up -d postgres redis
docker compose --env-file /opt/forem/config/forem.env run --rm web bundle exec rails db:prepare
docker compose --env-file /opt/forem/config/forem.env up -d web worker
```

Database preparation completed successfully.

## Public Verification

Public URL:

```text
https://club.bannaa.ai
```

Verified result:

```text
HTTP 200
HTML title: Bannaa
```

The HTTP endpoint redirects:

```text
http://club.bannaa.ai -> https://club.bannaa.ai/
```

## Temporary Workaround Applied

The upstream image `quay.io/forem/forem:latest` started, but the homepage initially returned 500 due to production asset issues:

```text
Asset `homePage.js` was not declared to be precompiled in production.
couldn't find file '@honeybadger-io/js/dist/browser/honeybadger.js'
```

Temporary smoke-test workaround applied inside `forem-web-1`:

- Created a minimal Honeybadger JS stub in the container.
- Added `homePage.js`, `homePageFeed.js`, and `homePageFeedShortcuts.js` to the asset manifest in the container.
- Ran `bundle exec rails assets:precompile`.
- Restarted `forem-web-1`.

After this, `https://club.bannaa.ai` returned `200`.

This workaround is not durable across container recreation. The real fix is a custom production image with assets correctly built.

## Remaining Work

1. Get GitHub org/user.
2. Fork Forem or create repo target.
3. Build custom image:

   ```text
   ghcr.io/moeghashim/bannaa-club:production
   ```

4. Implement Arabic locale files and RTL support in the Forem fork.
5. Ensure production assets build cleanly in the image.
6. Replace temporary upstream image on the VPS.
7. Run Arabic acceptance QA.
8. Rotate Resend API key.
9. Remove root password from local secrets or rotate root password.
10. Add backup automation.
11. Consider upgrading from KVM 1 before real production traffic.

## Useful Commands

SSH:

```bash
set -a
. deploy/secrets/ssh-access.env
set +a
ssh -i ~/.ssh/forem_hostinger_bsocial -p "${SSH_PORT:-22}" "${SSH_USER}@${SSH_HOST}"
```

Forem status:

```bash
cd /docker/forem
docker compose --env-file /opt/forem/config/forem.env ps
```

Forem logs:

```bash
cd /docker/forem
docker compose --env-file /opt/forem/config/forem.env logs --tail=200 web
docker compose --env-file /opt/forem/config/forem.env logs --tail=200 worker
```

Restart web:

```bash
docker restart forem-web-1
```

Public check:

```bash
curl -I https://club.bannaa.ai
```

## 2026-05-04 21:17:02 CDT Update

User selected repository:

```text
https://github.com/moeghashim/bannaa-club
```

Repository/image target set to:

```text
FOREM_IMAGE=ghcr.io/moeghashim/bannaa-club:production
```

This repo is intended to hold the deployment scaffold and, next, the custom Arabic-enabled Forem image build path. The live VPS still runs the temporary upstream image until the custom image exists and is deployed.

## 2026-05-04 21:20:12 CDT Update

Initialized the local workspace as a git repository and pushed the deployment scaffold to:

```text
https://github.com/moeghashim/bannaa-club
```

Commit pushed:

```text
3f99e1f Add Forem Hostinger deployment scaffold
```

Before committing, staged content was scanned for obvious secret values. The real local secret files remained ignored:

```text
deploy/config/forem.env
deploy/secrets/ssh-access.env
```

The repository now contains `AGENTS.md`, which instructs future agents to read this `progress.md` file before making changes.
