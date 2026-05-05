# Required Values From User

Use a one-time secret link, 1Password share, or Bitwarden Send for secret values.

## Known Values

```text
Domain: club.bannaa.ai
Email provider: Resend SMTP
SMTP host: smtp.resend.com
SMTP port: 587
SMTP username: resend
Default locale: ar
```

## Needed From You

Non-secret:

```text
VPS IP:
Hostinger VPS plan:
Is the VPS empty? yes/no
DNS provider for bannaa.ai:
GitHub org/user:
Community name:
Preferred sender email, default no-reply@club.bannaa.ai:
Container image target: ghcr.io/moeghashim/bannaa-club:production
```

Secret or sensitive:

```text
SSH access to VPS:
Resend API key:
DNS access or scoped DNS API token, if I should update records:
GitHub access or scoped token, if I should create/push repos/images:
Object storage keys, if uploads should use external storage immediately:
```

Already generated directly on the VPS:

```text
SECRET_KEY_BASE
FOREM_OWNER_SECRET
POSTGRES_PASSWORD
```

Still blocking container startup:

```text
FOREM_IMAGE
```

Filled:

```text
COMMUNITY_NAME
SMTP_PASSWORD
```

Current temporary smoke-test image:

```text
FOREM_IMAGE=quay.io/forem/forem:latest
```

Final Arabic image target:

```text
FOREM_IMAGE=ghcr.io/moeghashim/bannaa-club:production
```

## Values I Can Generate On The VPS

```text
SECRET_KEY_BASE
FOREM_OWNER_SECRET
POSTGRES_PASSWORD
SESSION_KEY if we decide to change it
```

## Resend Setup Required

Before email works reliably:

1. Add and verify `club.bannaa.ai` or `bannaa.ai` in Resend.
2. Add Resend DNS records at the DNS provider.
3. Create a Resend API key.
4. Share the API key through a secret-sharing tool.
