# Agent Instructions

Before making changes in this workspace, read:

```text
progress.md
```

Use `progress.md` as the source of truth for the current Forem Hostinger deployment state, decisions, remote paths, secrets handling, temporary workarounds, and remaining work.

After any meaningful change, append or update `progress.md` with:

- timestamp,
- files changed,
- remote commands run,
- deployment state,
- verification result,
- remaining blockers.

Do not print or commit secrets. The local ignored secret files are under:

```text
deploy/secrets/
deploy/config/forem.env
```

The live VPS deployment currently uses:

```text
/docker/forem/docker-compose.yml
/opt/forem/config/forem.env
```

