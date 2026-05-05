# Progress Log

This file is the working reference for the Forem on Hostinger Arabic deployment.

Last updated: 2026-05-04 22:36:13 CDT

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

## 2026-05-04 21:24:53 CDT Update

Added the first custom image build path for Bannaa Club.

New files:

```text
.github/workflows/build-forem-image.yml
build/README.md
build/scripts/apply-bannaa-overlays.sh
build/overlays/config/locales/ar.yml
build/overlays/config/locales/devise.ar.yml
build/overlays/config/locales/kaminari.ar.yml
build/overlays/config/locales/languages/ar.yml
build/overlays/config/initializers/bannaa_arabic_i18n.rb
build/overlays/app/assets/stylesheets/bannaa_rtl.css
```

Build strategy:

- Keep this repo as a small overlay/deployment repo.
- GitHub Actions clones upstream `forem/forem` at build time.
- The overlay script copies Arabic files and patches small integration points.
- Docker builds Forem's upstream `production` target.
- Published target remains:

  ```text
  ghcr.io/moeghashim/bannaa-club:production
  ```

Arabic overlay scope:

- Initial Arabic locale file.
- Arabic Devise starter translations.
- Arabic Kaminari pagination translations.
- Arabic language display names.
- Adds `ar` to Forem's locale route allowlist.
- Makes `<html>` use dynamic `lang` and `dir`.
- Adds `rtl_locale?` helper.
- Adds RTL CSS.
- Adds Arabic to the admin default-locale selector.
- Adds required production asset manifest links.

Local validation performed:

```text
build/scripts/apply-bannaa-overlays.sh /tmp/forem-overlay-test
YAML parse for config/locales/**/*.yml
ruby -c app/helpers/application_helper.rb
```

Next step: push this workflow and run GitHub Actions to build/publish `ghcr.io/moeghashim/bannaa-club:production`.

## 2026-05-04 21:31:34 CDT Update

The first GitHub Actions custom image build failed during Forem asset precompile.

Failed workflow:

```text
Build Forem Image
Run ID: 25354553467
Commit: 59fc984
Result: failure
```

Root cause:

```text
Sprockets::FileNotFound: couldn't find file 'homePage.js'
```

The overlay script had appended direct manifest links for:

```text
homePage.js
homePageFeed.js
homePageFeedShortcuts.js
```

Forem's upstream manifest already contains:

```text
//= link_tree ../builds
```

and the Docker build generates those files under `app/assets/builds`. The direct Sprockets links were removed from the overlay. The overlay now adds only:

```text
//= link bannaa_rtl.css
```

Files changed:

```text
build/scripts/apply-bannaa-overlays.sh
build/README.md
progress.md
```

Validation performed against a fresh upstream Forem checkout at `/tmp/forem-overlay-test-buildfix`:

```text
build/scripts/apply-bannaa-overlays.sh /tmp/forem-overlay-test-buildfix
YAML parse for config/locales/**/*.yml
ruby -c app/helpers/application_helper.rb
manifest check for problematic JS links
```

Result:

```text
YAML OK
Syntax OK
Only bannaa_rtl.css is directly added to app/assets/config/manifest.js
```

Next step: commit and push the build-fix patch, then watch the next GitHub Actions image build.

## 2026-05-04 22:01:02 CDT Update

The build-fix patch was committed and pushed:

```text
a778dd3 Fix Forem image asset manifest overlay
```

GitHub Actions run:

```text
Run ID: 25354730954
Result: success
Published image: ghcr.io/moeghashim/bannaa-club:production
Digest pulled on VPS: sha256:bf7ebc8da25ba24b3e5027fa637f034da350f712bd9a0773f85aab3e83450966
```

The VPS was updated to use the custom image:

```text
FOREM_IMAGE=ghcr.io/moeghashim/bannaa-club:production
```

Remote commands run:

```text
docker pull ghcr.io/moeghashim/bannaa-club:production
cp /opt/forem/config/forem.env /opt/forem/config/forem.env.bak.<timestamp>
sed -i to update FOREM_IMAGE
docker compose --env-file /opt/forem/config/forem.env run --rm web bundle exec rails db:migrate
docker compose --env-file /opt/forem/config/forem.env up -d web worker
```

After deployment, the homepage returned 500 due to a durable image asset gap:

```text
Asset `homePage.js` was not declared to be precompiled in production.
couldn't find file '@honeybadger-io/js/dist/browser/honeybadger.js'
```

Root cause refinement:

- Forem's Docker build generates JS bundles into `app/assets/builds`.
- Direct manifest links are required for the home bundles used by `javascript_include_tag "homePage"`.
- During image build, `app/assets/builds` must exist before Rails initializes asset paths.
- Without that directory present early, direct links fail during CI; without direct links, runtime requests fail.

Temporary live workaround applied inside `forem-web-1`:

```text
created a minimal Honeybadger browser JS stub
added direct manifest links for homePage.js, homePageFeed.js, homePageFeedShortcuts.js
ran RAILS_ENV=production NODE_ENV=production bundle exec rails assets:precompile
restarted forem-web-1
```

Verification after temporary workaround:

```text
https://club.bannaa.ai/ -> HTTP 200
https://club.bannaa.ai/robots.txt -> HTTP 200
```

Durable overlay fix prepared locally:

```text
build/overlays/app/assets/builds/.keep
build/scripts/apply-bannaa-overlays.sh
build/README.md
progress.md
```

The overlay now:

- keeps `app/assets/builds` present before Rails boots during image build,
- adds direct manifest links for `homePage.js`, `homePageFeed.js`, and `homePageFeedShortcuts.js`,
- keeps the RTL stylesheet manifest link.

Local validation performed against a fresh upstream Forem checkout at `/tmp/forem-overlay-test-buildfix2`:

```text
build/scripts/apply-bannaa-overlays.sh /tmp/forem-overlay-test-buildfix2
test -d app/assets/builds
YAML parse for config/locales/**/*.yml
ruby -c app/helpers/application_helper.rb
manifest check for homePage/homePageFeed/homePageFeedShortcuts/bannaa_rtl links
```

Result:

```text
builds dir OK
YAML OK
Syntax OK
manifest links present
```

Next step: commit and push the durable asset-path fix, watch the next image build, then pull/recreate the VPS containers from the rebuilt image so the temporary live workaround is no longer needed.

## 2026-05-04 22:15:26 CDT Update

The durable asset-path fix was committed and pushed:

```text
e5b7d2b Fix Forem build asset path setup
```

GitHub Actions run:

```text
Run ID: 25355526314
Result: success
Published image: ghcr.io/moeghashim/bannaa-club:production
```

The VPS pulled the rebuilt `production` tag:

```text
Digest: sha256:6fc2105c4da0841e97fa5f0bd29af117fdea73bf457ee2b3942cd1f457b1199e
```

Remote commands run:

```text
docker pull ghcr.io/moeghashim/bannaa-club:production
docker compose --env-file /opt/forem/config/forem.env up -d --force-recreate web worker
docker inspect forem-web-1
```

Clean recreated container verification:

```text
public/assets manifest contains bannaa_rtl.css
public/assets manifest contains homePage.js
public/assets manifest contains homePageFeed.js
public/assets manifest contains homePageFeedShortcuts.js
```

Runtime locale was still `en` because Forem stores default locale in the database settings table. Updated it through Rails:

```text
Settings::UserExperience.default_locale = "ar"
```

Then restarted web and worker so the setting cache was refreshed.

Final public verification:

```text
https://club.bannaa.ai/ -> HTTP 200
https://club.bannaa.ai/robots.txt -> HTTP 200
Rendered HTML: <html lang="ar" dir="rtl">
RTL stylesheet present: bannaa_rtl
Image running on VPS: ghcr.io/moeghashim/bannaa-club:production
Image digest: sha256:6fc2105c4da0841e97fa5f0bd29af117fdea73bf457ee2b3942cd1f457b1199e
```

Current deployment state:

- Forem runs next to existing Hostinger Traefik/OpenClaw.
- No second Traefik was created.
- Web and worker use the custom GHCR image.
- The temporary in-container asset workaround has been replaced by a clean recreated container from the rebuilt image.

Remaining work from the original plan:

1. Expand Arabic translation coverage beyond the starter locale files.
2. Perform Arabic UX acceptance QA: signup, login, article editor, comments, onboarding, admin settings, email templates, and mobile layout.
3. Verify Resend domain authentication and send a real transactional email test.
4. Create the first admin/owner account using `FOREM_OWNER_SECRET`.
5. Rotate the Resend API key because it was pasted into chat earlier.
6. Remove or rotate the root password stored in local ignored secrets after SSH key access is confirmed stable.
7. Add automated Postgres backups and a restore drill.
8. Add basic uptime/log monitoring.
9. Consider upgrading Hostinger KVM1 before real traffic.

## 2026-05-04 22:17:09 CDT Update

User provided Bannaa design reference:

```text
https://github.com/moeghashim/bannaa/blob/main/DESIGN.md
```

Added a compact local implementation reference:

```text
design/BANNAA_DESIGN_REFERENCE.md
```

Updated agent instructions:

```text
AGENTS.md
```

Future Forem UI, CSS, brand, layout, Arabic RTL, or theme work should read `design/BANNAA_DESIGN_REFERENCE.md` before editing. The design direction is terminal brutalism: Arabic-first, dense, flat, high-contrast, sharp 2px-radius surfaces, one accent per theme, IBM Plex Sans Arabic for Arabic/body text, JetBrains Mono only for technical metadata, and CSS logical properties for RTL mirroring.

Deployment state unchanged:

```text
https://club.bannaa.ai/ -> HTTP 200
Live image: ghcr.io/moeghashim/bannaa-club:production
```

Remaining design-specific work: implement a Forem brand-theme overlay using the Bannaa design tokens. The current live deployment has Arabic/RTL support, but not the full terminal-brutalist visual theme yet.

## 2026-05-04 22:21:19 CDT Update

User requested the Bannaa light theme.

Prepared a Forem overlay implementation that keeps the change update-safe:

```text
build/overlays/app/assets/stylesheets/bannaa_light.css
build/scripts/apply-bannaa-overlays.sh
build/README.md
progress.md
```

Light theme overlay scope:

- Uses Bannaa light palette: white canvas, bone/linen surfaces, carbon text, industrial orange accent.
- Overrides Forem/Crayons color variables where possible instead of broad template edits.
- Keeps 2px radii for buttons/cards/forms.
- Removes shadows/lift from major surfaces.
- Adds compact operator status ribbon.
- Uses IBM Plex Sans Arabic for body/Arabic text, Rubik for display roles, and JetBrains Mono for technical metadata.
- Keeps RTL-specific behavior in `bannaa_rtl.css`.

Overlay integration:

```text
app/views/layouts/application.html.erb links bannaa_light.css for all locales
app/views/layouts/application.html.erb links bannaa_rtl.css only for RTL locales
app/assets/config/manifest.js links bannaa_light.css and bannaa_rtl.css
```

Local validation against fresh upstream Forem checkout:

```text
build/scripts/apply-bannaa-overlays.sh /tmp/forem-overlay-test-light
YAML parse for config/locales/**/*.yml
ruby -c app/helpers/application_helper.rb
layout check for bannaa_light/bannaa_rtl stylesheet links
manifest check for bannaa_light/bannaa_rtl asset links
```

Result:

```text
YAML OK
Syntax OK
styles OK
```

Next step: commit and push, wait for GitHub Actions image build, deploy the rebuilt image to the VPS, and verify `https://club.bannaa.ai/` still renders `lang="ar" dir="rtl"` with `bannaa_light` and `bannaa_rtl` assets.

## 2026-05-04 22:36:13 CDT Update

The Bannaa light theme overlay was committed and pushed:

```text
532ba3f Add Bannaa light theme overlay
```

GitHub Actions image build:

```text
Run ID: 25356069155
Result: success
Published image: ghcr.io/moeghashim/bannaa-club:production
```

VPS deployment:

```text
docker pull ghcr.io/moeghashim/bannaa-club:production
docker compose --env-file /opt/forem/config/forem.env up -d --force-recreate web worker
```

The first `docker pull` attempt failed due to a transient GHCR network reset. Retrying the same pull succeeded.

New live image digest:

```text
sha256:9d4ca9fba091a292b77f7170dab6d11d4c4f5ab5bebde426267673da495588ed
```

Verification:

```text
https://club.bannaa.ai/?_light_theme_check=2 -> HTTP 200
Rendered HTML: <html lang="ar" dir="rtl">
Loaded CSS: bannaa_light-2d41ca2423db7979b05ddacacbcf12866f3eab384895416eeccfbdd31f66456b.css
Loaded CSS: bannaa_rtl-5acb4e8e7963032dc8baf3576f83f9b330456e7c83d8d80ece5e9d4de5823a4e.css
CSS asset check: /assets/bannaa_light-...css -> HTTP 200
CSS asset check: /assets/bannaa_rtl-...css -> HTTP 200
```

Note: the live page loads the light theme and RTL assets. Visual QA in a browser is still recommended for final polish across desktop/mobile because this was verified through HTML/CSS asset checks and HTTP responses, not a rendered screenshot review.
