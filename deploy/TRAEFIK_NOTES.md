# Traefik Notes

The existing Hostinger VPS already runs Traefik:

```text
container: traefik-traefik-1
compose path: /docker/traefik/docker-compose.yml
network mode: host
ports: 80, 443
provider: Docker
exposedByDefault: false
certificate resolver: letsencrypt
```

OpenClaw is already exposed through Docker labels, so Forem should use the same pattern.

Forem should be a separate Compose project:

```text
/docker/forem/docker-compose.yml
```

It should not create another Traefik container.

Forem's `web` service needs labels:

```yaml
labels:
  - traefik.enable=true
  - traefik.http.routers.forem.rule=Host(`${APP_DOMAIN}`)
  - traefik.http.routers.forem.entrypoints=websecure
  - traefik.http.routers.forem.tls.certresolver=letsencrypt
  - traefik.http.services.forem.loadbalancer.server.port=3000
```

Do not install Caddy or bind another public proxy to ports 80/443 while this Traefik stack is kept.

For `club.bannaa.ai`, DNS must point to:

```text
A club 31.97.6.123
```

Traefik will request the Let's Encrypt certificate after DNS points to the VPS and the Forem web container has matching labels.
