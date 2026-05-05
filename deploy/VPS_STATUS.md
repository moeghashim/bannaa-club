# VPS Status

Last checked: 2026-05-04 America/Chicago

## Access

```text
SSH host: set in deploy/secrets/ssh-access.env
SSH user: root
Key access: working
Password file: deploy/secrets/ssh-access.env, ignored by git, mode 600
```

The project SSH public key has been installed on the VPS root account.

## Server

```text
Hostname: wasimo
OS: Ubuntu 24.04.4 LTS
CPU: 1 vCPU
Memory: 3.8 GiB
Swap: none
Disk: 50 GB total, about 40 GB free
Docker: installed and running
Docker Compose: installed
Podman: not installed
```

## Existing Services

Existing containers are already running:

```text
traefik-traefik-1
openclaw-e2dq-openclaw-1
```

Ports already in use:

```text
80/tcp: traefik
443/tcp: traefik
46143/tcp: openclaw
22/tcp: ssh
```

## Deployment Implication

Do not install Caddy or bind Forem directly to ports 80/443 until we decide what to do with the existing Traefik/OpenClaw stack.

Safer options:

1. Add Forem behind the existing Traefik proxy.
2. Stop/remove the existing Traefik/OpenClaw stack if it is not needed.
3. Run Forem on an internal port first for proof of concept, then wire public TLS after DNS/proxy decision.

## Recommended Next Step

Decision confirmed by user:

```text
Keep existing OpenClaw/Traefik? yes
```

Forem should be added as another backend behind the existing Traefik Docker provider.

Forem deployment location:

```text
/docker/forem/docker-compose.yml
/opt/forem/config/forem.env
/opt/forem/postgres
/opt/forem/redis
/opt/forem/uploads
```

Current Forem setup state:

```text
/docker/forem/docker-compose.yml: created
/opt/forem/config/forem.env: created, mode 600
SECRET_KEY_BASE: generated on VPS
FOREM_OWNER_SECRET: generated on VPS
POSTGRES_PASSWORD: generated on VPS
containers started: yes
current image: quay.io/forem/forem:latest
public URL: https://club.bannaa.ai
public HTTP status: 200
```

Important caveat:

```text
This is currently the upstream Forem image, not the custom Arabic image.
An in-container asset precompile workaround was applied for smoke testing.
That workaround is not durable across container recreation.
The production fix is to build and deploy our own image with assets and Arabic support included.
```

Filled:

```text
COMMUNITY_NAME
SMTP_PASSWORD
```

Next image target:

```text
FOREM_IMAGE=ghcr.io/moeghashim/bannaa-club:production
```

Required Traefik route:

```text
Host: club.bannaa.ai
Container service: web
Internal port: 3000
TLS resolver: letsencrypt
```
