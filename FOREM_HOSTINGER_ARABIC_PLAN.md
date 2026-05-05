# Forem on Hostinger With Arabic Interface

## Goal

Deploy a production Forem community on Hostinger VPS and maintain an Arabic user interface without creating a hard-to-update private fork.

The implementation should:

- Run Forem on Hostinger VPS.
- Support Arabic UI strings and right-to-left layout.
- Accept Arabic user-generated content: names, bios, posts, comments, search queries, and tags where Forem permits them.
- Keep Forem upstream updates manageable.
- Keep deployment repeatable through scripts and documented server state.

## Hosting Decision

Use the existing Hostinger VPS, not shared hosting, WordPress hosting, or Hostinger cloud hosting.

Target plan:

- If the existing VPS is KVM 4 or higher, keep it.
- If the existing VPS is KVM 2, use it for initial deployment and upgrade only if memory, CPU, or disk pressure appears.
- Current VPS plan: KVM 1.
- Use KVM 1 only for installation testing, proof of concept, and Arabic UI development.
- Upgrade before public production launch. Forem is likely to be too tight on KVM 1 for a reliable community because Rails, Postgres, Redis, Sidekiq, image handling, and background jobs compete for limited CPU and memory.

Target OS:

- Current VPS OS: Ubuntu 24.04.
- Use the Ubuntu 24.04 deployment path.
- Do not rebuild the VPS unless inventory shows a hard blocker.
- If the VPS currently hosts anything important, take a snapshot and inventory before changing services.

Why this differs from Forem's official default:

- Forem self-hosting is built around Fedora CoreOS, Podman, containers, and systemd.
- Hostinger does not support custom OS images, so Fedora CoreOS cannot be installed exactly.
- Because the existing VPS is already on Ubuntu 24.04, we will use Docker Compose for the primary deployment instead of rebuilding first.

## Constraints

Hostinger-specific constraints:

- Hostinger VPS is unmanaged; server patching, firewall, monitoring, backups, and incident response are our responsibility.
- Hostinger does not support uploading a custom OS image, so Forem's exact Fedora CoreOS playbook cannot be used unchanged.
- Forem's official self-host playbook supports DigitalOcean, AWS, Google Cloud, bare metal, and QEMU-style local development. Hostinger must be treated as custom bare-metal-style VPS work.

Forem-specific constraints:

- Forem is not a simple Rails app. It includes Rails, Postgres, Redis, Sidekiq, image handling, proxy/TLS, background jobs, and caches.
- Forem i18n is still marked experimental in upstream docs.
- Admin backend localization is not a phase-one target.
- User-generated content should not be auto-translated.

## Access Needed

I can handle the setup once these are available:

- Hostinger hPanel access to the existing VPS, preferably through Account Sharing.
- SSH access to the existing VPS.
- Domain name access for DNS changes.
- GitHub repository or organization where the Arabic Forem fork and container image will live.
- Email provider credentials for transactional mail.
- Object storage credentials if we externalize uploads.
- Optional: Cloudflare access if DNS/CDN/WAF will be handled there.

Do not send passwords, API tokens, private keys, recovery codes, or production secrets in plain chat.

Preferred access methods:

1. Hostinger hPanel:

   - Use Hostinger Account Sharing.
   - Grant Collaborator access to the VPS service only if Hostinger lets you scope it that narrowly.
   - Avoid sharing your main Hostinger password.
   - Do not grant Admin access unless purchase/billing operations are explicitly needed.

2. VPS SSH:

   - Add my SSH public key to `/root/.ssh/authorized_keys` or to a temporary sudo user.
   - If you cannot add a key, create a temporary password, send it through a secret-sharing tool, and require password rotation immediately after setup.

3. GitHub:

   - Add me as a collaborator to the fork/deployment repository, or create a scoped deploy token.
   - For GitHub Container Registry, use a fine-scoped token with package write access only if needed.

4. DNS:

   - Prefer scoped Cloudflare or DNS-provider access.
   - If DNS is inside Hostinger, hPanel Account Sharing may be enough.

5. Production secrets:

   - Put secrets directly on the VPS in `/opt/forem/config/forem.env`.
   - Keep `forem.env` out of git.
   - Use `chmod 600` and root/deploy ownership.

Recommended secret-sharing tools:

- 1Password item sharing.
- Bitwarden Send.
- `onetimesecret.com` or equivalent one-time secret link.
- Age/GPG-encrypted file if you already use public-key encryption.

Secrets that must never be committed:

- Hostinger login credentials.
- SSH private keys.
- `SECRET_KEY_BASE`.
- Postgres password.
- Redis password if configured.
- SMTP password/API key.
- Object storage access keys.
- GitHub personal access tokens.
- Cloudflare/API tokens.

## Architecture

Initial single-server architecture:

- Hostinger KVM VPS.
- Current plan: KVM 1.
- Ubuntu 24.04.
- Docker Engine for containers.
- Docker Compose to manage Forem services.
- Forem web container.
- Sidekiq worker container.
- Postgres on the same VPS for phase one.
- Redis on the same VPS for phase one.
- Reverse proxy with TLS.
- Persistent data under `/opt/forem`.
- Server backups plus off-server database dumps.

Prepared local deployment scaffold:

```text
deploy/
  README.md
  REQUIRED_FROM_USER.md
  config/
    Caddyfile.example
    forem.env.example
  compose.yml.example
  scripts/
    inventory.sh
    bootstrap-ubuntu.sh
    bootstrap-fedora.sh
    install-units.sh
    backup-postgres.sh
    update-image.sh
  systemd/        reference only
    forem-postgres.service
    forem-redis.service
    forem-web.service
    forem-worker.service
    forem-backup.service
    forem-backup.timer
```

These files are templates until the VPS inventory confirms the OS, running services, available memory, and whether the server is safe to modify.

Future scale-out path:

- First upgrade target: KVM 2 minimum.
- Recommended production target: KVM 4.
- Move Postgres to a managed database or separate VPS.
- Move Redis to a separate service if needed.
- Move uploads to S3-compatible object storage.
- Add CDN/WAF through Cloudflare.
- Add a second worker box only after traffic requires it.

## Repository Strategy

Use two repositories:

1. Forem fork:

   ```text
   github.com/<org>/forem
   ```

2. Deployment repo:

   ```text
   github.com/<org>/forem-hostinger-deploy
   ```

The Forem fork contains application changes only:

- Arabic locale files.
- i18n extraction fixes.
- RTL helpers.
- Tests.
- Minimal deployment metadata only if required.

The deployment repo contains:

- Hostinger bootstrap scripts.
- Docker Compose template.
- backup scripts.
- update scripts.
- monitoring notes.
- server inventory.

Do not mix deployment secrets or one-off server edits into the Forem app fork.

## Branch Strategy

Keep `main` clean and synced with upstream:

```bash
git remote add upstream https://github.com/forem/forem.git
git checkout main
git pull --rebase upstream main
```

Create small topic branches:

```text
arabic-locale-files
arabic-rtl-layout
arabic-user-input-qa
arabic-locale-selection
arabic-production-hardening
```

Prefer upstreamable changes:

- hard-coded string extraction
- locale-aware cache keys
- RTL-safe CSS improvements
- Unicode slug fixes
- tests for Arabic content

Avoid:

- large custom theme rewrites
- monkey patches
- edited third-party packages
- permanent local-only changes in upstream-owned files unless they are tiny and well-tested

## Phase 0: Existing VPS Inventory

Before changing anything, collect the current server state.

1. Confirm Hostinger plan and location:

   ```text
   VPS plan:
   CPU:
   RAM:
   disk:
   region:
   current OS:
   current public IPv4:
   current public IPv6:
   ```

2. Confirm whether the VPS is disposable.

   - We are not planning to rebuild.
   - If it contains existing services, take inventory and backup before changing anything.

3. Initial server commands:

   ```bash
   ssh root@<server_ip> 'bash -s' < deploy/scripts/inventory.sh
   ```

4. Container/runtime check:

   ```bash
   podman --version || true
   docker --version || true
   docker compose version || true
   ```

5. Existing service check:

   ```bash
   systemctl list-units --type=service --state=running
   crontab -l || true
   ls -la /opt /srv /var/www
   ```

6. Backup before destructive changes:

   - Take a Hostinger snapshot if available.
   - Copy anything important under `/opt`, `/srv`, `/var/www`, and home directories.
   - Export databases if MySQL/Postgres already exist.

## Phase 1: Hostinger VPS Setup

1. Use the existing VPS.

   Preferred existing target:

   ```text
   Current: KVM 1
   Ubuntu 24.04
   KVM 1 acceptable for proof of concept only
   KVM 2 minimum for small private beta
   KVM 4 recommended for production
   ```

2. Configure SSH access.

   On local machine:

   ```bash
   ssh-keygen -t ed25519 -C "forem-hostinger-deploy" -f ~/.ssh/forem_hostinger
   ```

   Add the public key to Hostinger or the server:

   ```bash
   cat ~/.ssh/forem_hostinger.pub
   ```

   Add the public key through Hostinger hPanel if available, or append it on the server:

   ```bash
   mkdir -p /root/.ssh
   chmod 700 /root/.ssh
   printf '%s\n' '<public_key_here>' >> /root/.ssh/authorized_keys
   chmod 600 /root/.ssh/authorized_keys
   ```

3. SSH into the existing server.

   ```bash
   ssh -i ~/.ssh/forem_hostinger root@<server_ip>
   ```

4. Create a non-root deploy user.

   ```bash
   useradd -m -s /bin/bash deploy
   mkdir -p /home/deploy/.ssh
   cp /root/.ssh/authorized_keys /home/deploy/.ssh/authorized_keys
   chown -R deploy:deploy /home/deploy/.ssh
   chmod 700 /home/deploy/.ssh
   chmod 600 /home/deploy/.ssh/authorized_keys
   usermod -aG wheel deploy
   ```

5. Patch Ubuntu.

   ```bash
   apt update
   apt upgrade -y
   reboot
   ```

6. Install server packages.

   ```bash
   apt install -y git curl jq vim tmux htop fail2ban ufw ca-certificates
   systemctl enable --now fail2ban
   ```

7. Configure firewall.

   ```bash
   ufw allow OpenSSH
   ufw allow http
   ufw allow https
   ufw --force enable
   ```

8. Create Forem directories.

   ```bash
   mkdir -p /opt/forem
   mkdir -p /opt/forem/{config,data,postgres,redis,uploads,backups,scripts}
   chown -R deploy:deploy /opt/forem
   ```

## Phase 2: DNS and TLS

1. Point DNS to Hostinger VPS.

   Required records:

   ```text
   A     @      <server_ip>
   A     www    <server_ip>
   AAAA  @      <server_ipv6>     optional
   AAAA  www    <server_ipv6>     optional
   ```

2. Recommended DNS provider:

   - Cloudflare if we want WAF, caching, DNS automation, and easier protection.
   - Hostinger DNS is acceptable for a simpler setup.

3. TLS:

   - Use the Forem self-host proxy pattern where practical.
   - Otherwise use Caddy or Traefik as the TLS terminator.

Preferred initial proxy if custom Hostinger work is needed:

- Caddy for simple automatic Let's Encrypt TLS.

Reason:

- It reduces custom TLS maintenance on a non-official provider.
- It is easy to replace later if we move closer to Forem's upstream OpenResty/Traefik setup.

## Phase 3: Build Arabic Forem Image

1. Fork Forem.

   ```bash
   git clone git@github.com:<org>/forem.git
   cd forem
   git remote add upstream https://github.com/forem/forem.git
   ```

2. Create Arabic work branch.

   ```bash
   git checkout -b arabic-locale-files
   ```

3. Add Arabic locale files that mirror upstream structure:

   ```text
   config/locales/ar.yml
   config/locales/devise.ar.yml
   config/locales/devise_invitable.ar.yml
   config/locales/kaminari.ar.yml
   config/locales/languages/ar.yml
   config/locales/views/**/ar.yml
   config/locales/models/**/ar.yml
   config/locales/mailers/**/ar.yml
   ```

4. Add Arabic pluralization support if not already covered by Forem dependencies.

5. Convert hard-coded member-facing strings incrementally.

6. Add RTL support:

   - `dir="rtl"` when `I18n.locale == :ar`.
   - `lang="ar"` on Arabic pages.
   - CSS logical properties where possible.
   - Small scoped `html[dir="rtl"]` fixes where needed.

7. Run tests:

   ```bash
   bundle exec i18n-tasks health
   ./bin/rails db:test:prepare RAILS_ENV=test
   ./bin/rspec
   yarn lint
   yarn test
   ```

8. Build and publish the image.

   Example target:

   ```text
   ghcr.io/<org>/forem-arabic:<git_sha>
   ```

   Also maintain a stable deployment tag:

   ```text
   ghcr.io/<org>/forem-arabic:production
   ```

## Phase 4: Deploy on Hostinger

1. Create production env file on the VPS:

   ```text
   /opt/forem/config/forem.env
   ```

   It should include:

   ```text
   APP_DOMAIN=<domain>
   SECRET_KEY_BASE=<secret>
   DATABASE_URL=<postgres_url>
   REDIS_URL=<redis_url>
   RAILS_ENV=production
   RACK_ENV=production
   DEFAULT_LOCALE=ar
   ```

   Exact variable names must be verified against current Forem upstream before final deployment.

2. Create Docker Compose volumes/directories:

   ```bash
   mkdir -p /opt/forem/postgres /opt/forem/redis /opt/forem/uploads
   chown -R deploy:deploy /opt/forem
   ```

3. Install Compose files:

   ```text
   /opt/forem/compose.yml
   /opt/forem/config/forem.env
   /opt/forem/config/Caddyfile
   ```

4. Start database and Redis first:

   ```bash
   docker compose --env-file /opt/forem/config/forem.env -f /opt/forem/compose.yml up -d postgres redis
   ```

5. Run database setup/migrations through the Forem image.

6. Start Forem web and worker:

   ```bash
   docker compose --env-file /opt/forem/config/forem.env -f /opt/forem/compose.yml up -d
   ```

7. Confirm health:

   ```bash
   docker compose --env-file /opt/forem/config/forem.env -f /opt/forem/compose.yml ps
   curl -I https://<domain>
   ```

8. Create first admin account through browser.

9. Set Arabic default locale through Forem admin if supported by current upstream.

## Phase 5: Arabic Acceptance QA

Test these flows in Arabic:

- Homepage at `/locale/ar`.
- Homepage with Arabic as default locale.
- Signup.
- Login.
- Onboarding.
- Profile edit.
- Arabic display name.
- Arabic bio.
- Article creation with Arabic title.
- Article creation with Arabic body.
- Markdown editor in RTL text.
- Comments in Arabic.
- Notifications.
- Search with Arabic query.
- Mobile layout.
- Email templates.

Also test mixed language content:

- Arabic UI with English post.
- English UI with Arabic post.
- Arabic post with English code blocks.
- LTR code blocks inside RTL article body.

## Phase 6: Backups

Back up at three layers:

1. Hostinger VPS snapshot.

   Frequency:

   ```text
   daily if affordable, otherwise before every deploy and weekly
   ```

2. Postgres dump.

   Script path:

   ```text
   /opt/forem/scripts/backup-postgres.sh
   ```

   Retention:

   ```text
   7 daily
   4 weekly
   3 monthly
   ```

3. Off-server copy.

   Target options:

   - S3-compatible storage.
   - Backblaze B2.
   - Cloudflare R2.
   - Another VPS via rsync.

Never rely only on Hostinger local snapshots.

## Phase 7: Updates

Weekly update routine:

1. Sync Forem fork:

   ```bash
   git checkout main
   git pull --rebase upstream main
   git push origin main
   ```

2. Rebase Arabic branches:

   ```bash
   git checkout arabic-locale-files
   git rebase main
   ```

3. Run tests.

4. Build new image:

   ```text
   ghcr.io/<org>/forem-arabic:<new_git_sha>
   ```

5. Deploy to staging first if available.

6. Backup production.

7. Update production image tag.

8. Run migrations.

9. Restart services.

10. Smoke test.

Rollback plan:

- Keep previous image tag recorded in `/opt/forem/version`.
- Keep latest database backup before migration.
- Roll back image quickly if app boot fails.
- Restore database only if migration rollback is impossible.

## Phase 8: Monitoring

Minimum monitoring:

- Hostinger VPS resource charts.
- Docker Compose service status.
- disk usage alert.
- uptime check.
- backup success check.
- log rotation.

Install basics:

```bash
dnf install -y logrotate
```

Useful checks:

```bash
df -h
free -m
docker compose --env-file /opt/forem/config/forem.env -f /opt/forem/compose.yml ps
docker compose --env-file /opt/forem/config/forem.env -f /opt/forem/compose.yml logs --tail=200 web
docker compose --env-file /opt/forem/config/forem.env -f /opt/forem/compose.yml logs --tail=200 worker
```

Optional:

- Uptime Kuma.
- Sentry.
- Grafana/Prometheus.
- Better Stack.

## Phase 9: Security

Required:

- SSH keys only.
- Disable password root login after deploy user is confirmed.
- Firewall only exposes 22, 80, 443.
- Regular OS updates.
- Production secrets outside git.
- Database not exposed publicly.
- Redis not exposed publicly.
- Backups encrypted before leaving the server.

SSH hardening after access is confirmed:

```text
PermitRootLogin prohibit-password
PasswordAuthentication no
PubkeyAuthentication yes
```

Then:

```bash
systemctl restart sshd
```

## Execution Checklist

### Hostinger

- [ ] Confirm existing VPS plan.
- [x] Confirm existing VPS plan: KVM 1.
- [x] Confirm existing VPS OS: Ubuntu 24.04.
- [ ] Confirm whether VPS is empty or has existing services.
- [ ] Take Hostinger snapshot before destructive changes.
- [ ] Add SSH key.
- [ ] Confirm SSH access.
- [ ] Patch OS.
- [ ] Create deploy user.
- [ ] Configure firewall.
- [ ] Create `/opt/forem`.

### DNS

- [ ] Choose DNS provider.
- [ ] Add root A record.
- [ ] Add www A record.
- [ ] Confirm DNS propagation.
- [ ] Issue TLS cert.

### Forem Fork

- [ ] Fork Forem.
- [ ] Add upstream remote.
- [ ] Add Arabic locale files.
- [ ] Add RTL helper.
- [ ] Fix hard-coded strings in member-facing flows.
- [ ] Add Arabic content tests.
- [ ] Run i18n health checks.
- [ ] Build image.
- [ ] Push image.

### Deployment

- [ ] Create env file.
- [ ] Create Docker Compose file.
- [ ] Start Postgres.
- [ ] Start Redis.
- [ ] Run migrations.
- [ ] Start web.
- [ ] Start worker.
- [ ] Start proxy.
- [ ] Create admin.
- [ ] Set Arabic default locale.

### QA

- [ ] Arabic homepage.
- [ ] Arabic signup/login.
- [ ] Arabic article editor.
- [ ] Arabic article page.
- [ ] Arabic comments.
- [ ] Arabic profile.
- [ ] Arabic search.
- [ ] Mobile RTL layout.
- [ ] Emails.
- [ ] Backup restore test.

## Immediate Next Actions

1. Current deployment state:

   ```text
   VPS IP: 31.97.6.123
   VPS plan: KVM 1
   Current OS: Ubuntu 24.04
   Domain name: club.bannaa.ai
   Existing Traefik/OpenClaw: kept
   Forem Compose path: /docker/forem/docker-compose.yml
   Forem env path: /opt/forem/config/forem.env
   Temporary image: quay.io/forem/forem:latest
   Public status: 200 OK
   ```

2. Remaining values/work for final Arabic production image:

   ```text
   GitHub org/user:
   GitHub repository: https://github.com/moeghashim/bannaa-club
   Final image target: ghcr.io/moeghashim/bannaa-club:production
   ```

3. Share access safely:

   - Preferred: Hostinger Account Sharing with Collaborator access.
   - Add my SSH public key to the VPS, or send a temporary SSH credential through a one-time secret tool.
   - Add GitHub repo access or create the target org/repo.
   - Provide DNS access or confirm you will apply DNS records I specify.

4. I will then:

   - prepare the Forem fork,
   - implement Arabic support,
   - build the image,
   - replace the temporary upstream image,
   - run QA,
   - document update and rollback commands.

## References

- Forem repository: https://github.com/forem/forem
- Forem self-host repository: https://github.com/forem/selfhost
- Forem self-hosting docs: https://developers.forem.com/self-hosting
- Forem i18n overview: https://developers.forem.com/technical-overview/i18n
- Forem backend i18n docs: https://developers.forem.com/backend/internationalization
- Hostinger VPS limits: https://www.hostinger.com/support/6976044-parameters-and-limits-of-hosting-plans-in-hostinger/
- Hostinger VPS OS templates: https://www.hostinger.com/support/1583571-what-are-the-available-operating-systems-for-vps-at-hostinger/
- Hostinger custom OS limitation: https://www.hostinger.com/support/8852324-can-you-add-your-own-os-image-to-vps-at-hostinger/
- Hostinger Account Sharing: https://www.hostinger.com/support/4883367-how-to-get-shared-access-to-another-account
