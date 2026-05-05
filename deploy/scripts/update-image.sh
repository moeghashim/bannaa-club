#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:-}"

if [[ -z "$IMAGE" ]]; then
  echo "Usage: $0 ghcr.io/<org>/forem-arabic:<tag>" >&2
  exit 1
fi

if [[ ! -f /opt/forem/config/forem.env ]]; then
  echo "Missing /opt/forem/config/forem.env" >&2
  exit 1
fi

PREVIOUS="$(grep '^FOREM_IMAGE=' /opt/forem/config/forem.env 2>/dev/null | cut -d= -f2- || true)"
echo "Previous image: ${PREVIOUS:-unknown}"
echo "New image: ${IMAGE}"

docker pull "$IMAGE"

cp /opt/forem/config/forem.env /opt/forem/config/forem.env.bak

if grep -q '^FOREM_IMAGE=' /opt/forem/config/forem.env; then
  sed -i "s|^FOREM_IMAGE=.*|FOREM_IMAGE=${IMAGE}|" /opt/forem/config/forem.env
else
  printf '\nFOREM_IMAGE=%s\n' "$IMAGE" >> /opt/forem/config/forem.env
fi

docker compose --env-file /opt/forem/config/forem.env -f /opt/forem/compose.yml up -d

docker compose --env-file /opt/forem/config/forem.env -f /opt/forem/compose.yml ps
