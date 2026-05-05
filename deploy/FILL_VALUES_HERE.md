# Fill These Values

This is the short checklist. Do not paste secrets into chat.

## 1. SSH Access

If you want to store the root password in a local file, add it here:

```text
deploy/secrets/ssh-access.env
```

Exact entries:

```env
SSH_HOST=YOUR_VPS_IP_HERE
SSH_PORT=22
SSH_USER=root
SSH_PASSWORD=YOUR_ROOT_PASSWORD_HERE
```

This file is ignored by git.

Preferred key-based access is still below.

Add this public key to your Hostinger VPS:

```text
deploy/ssh/forem_hostinger_bsocial.pub
```

The public key content is:

```text
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGwyrWffFOOic/+CPbldYZ3GuptJ3dWZ3MNqKJva5YDv forem-hostinger-bsocial
```

Add it in one of these places:

Preferred through Hostinger:

```text
hPanel -> VPS -> SSH Keys
```

Or directly on the VPS:

```text
/root/.ssh/authorized_keys
```

Command if you are already logged in as root:

```bash
mkdir -p /root/.ssh
chmod 700 /root/.ssh
nano /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```

Paste the public key as one full line.

## 2. Production Env File

The file to edit locally is:

```text
deploy/config/forem.env
```

On the VPS, the same values will go here:

```text
/opt/forem/config/forem.env
```

Values already set:

```env
APP_DOMAIN=club.bannaa.ai
APP_PROTOCOL=https://
DEFAULT_LOCALE=ar
SMTP_ADDRESS=smtp.resend.com
SMTP_PORT=587
SMTP_DOMAIN=club.bannaa.ai
SMTP_USER_NAME=resend
```

You need to fill:

```env
COMMUNITY_NAME=your community name
SMTP_PASSWORD=your Resend API key
FOREM_IMAGE=ghcr.io/moeghashim/bannaa-club:production
```

Leave these as `GENERATE_ON_VPS`; I will generate them on the server:

```env
FOREM_OWNER_SECRET=GENERATE_ON_VPS
SECRET_KEY_BASE=GENERATE_ON_VPS
POSTGRES_PASSWORD=GENERATE_ON_VPS
```

## 3. DNS

Add this DNS record wherever `bannaa.ai` is managed:

```text
Type: A
Name: club
Value: <your Hostinger VPS IP>
TTL: Auto or 300
```

If you use Cloudflare, keep proxy off until TLS and the app are verified:

```text
Proxy status: DNS only
```

## 4. Resend

In Resend:

1. Add and verify either `bannaa.ai` or `club.bannaa.ai`.
2. Add Resend's DNS records at your DNS provider.
3. Create an API key.
4. Put the API key in the env file as:

```env
SMTP_PASSWORD=<resend api key>
```

## 5. Send Me These Non-Secret Values

These can be pasted in chat:

```text
VPS IP:
Is the VPS empty? yes/no
Can I reboot it if needed? yes/no
DNS provider:
GitHub org/user:
Community name:
```
