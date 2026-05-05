# Local Secrets

Files in this directory are for local access secrets only.

Do not commit real secrets.

Current local protections:

- `deploy/secrets/` is mode `700`.
- `deploy/secrets/ssh-access.env` is mode `600`.
- `.gitignore` excludes `deploy/secrets/*` except this README and `.example` files.

Use:

```text
deploy/secrets/ssh-access.env
```

for the Hostinger VPS root SSH password if you choose to store it locally.

After SSH key access is working, rotate or remove the root password from this file.
