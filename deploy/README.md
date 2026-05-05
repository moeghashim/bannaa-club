# Forem Hostinger Deployment Scaffold

This directory contains the first-pass deployment scaffold for running an Arabic-enabled Forem instance on an existing Hostinger VPS.

It is intentionally split into:

- `scripts/`: server inventory, bootstrap, backup, and update helpers.
- `config/`: environment and proxy templates.
- `compose.yml.example`: Docker Compose deployment template for Ubuntu 24.04.
- `systemd/`: older service templates retained as reference only.

Do not commit real secrets. Copy `config/forem.env.example` to `/opt/forem/config/forem.env` on the VPS and fill it there.

## Current Execution Boundary

Prepared locally:

- Server inventory script.
- Ubuntu 24.04 bootstrap script.
- Docker Compose template.
- Fedora/Podman files retained only as fallback/reference.
- Forem environment template.
- Caddy proxy template.
- systemd service templates.
- Postgres backup script.
- image update script.

Blocked until access is available:

- VPS inventory.
- OS/package bootstrap.
- DNS/TLS validation.
- actual Forem image deployment.
- production secret creation.
- admin account creation.

## Required Inputs

```text
VPS IP:
VPS plan:
Current OS: Ubuntu 24.04
Domain:
Is the VPS empty? yes/no
GitHub org/repo target:
Container image target:
DNS provider:
Email provider:
```

## First Remote Commands

After SSH access is available:

```bash
ssh root@<server_ip> 'bash -s' < deploy/scripts/inventory.sh
```

Review the output before running bootstrap.

Ubuntu 24.04:

```bash
ssh root@<server_ip> 'bash -s' < deploy/scripts/bootstrap-ubuntu.sh
```

Fedora reference only:

```bash
ssh root@<server_ip> 'bash -s' < deploy/scripts/bootstrap-fedora.sh
```

## Server Layout

```text
/opt/forem/
  backups/
  config/
    forem.env
    Caddyfile
  data/
  postgres/
  redis/
  scripts/
  systemd/
  uploads/
  version
```

The Compose project itself should live next to Hostinger's existing Docker projects:

```text
/docker/forem/docker-compose.yml
```

Traefik remains the existing Hostinger Traefik project under `/docker/traefik`.

## Secret Handling

Use one of:

- 1Password shared item.
- Bitwarden Send.
- one-time secret link.
- SSH key access instead of passwords.

Never paste secrets into chat or commit them to this repository.
