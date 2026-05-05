#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="${1:-/opt/forem/systemd}"

if [[ ! -d "$SRC_DIR" ]]; then
  echo "Missing systemd source directory: $SRC_DIR" >&2
  exit 1
fi

install -m 0644 "$SRC_DIR"/forem-*.service /etc/systemd/system/
install -m 0644 "$SRC_DIR"/forem-*.timer /etc/systemd/system/ 2>/dev/null || true

systemctl daemon-reload

echo "Installed Forem units. Enable them only after /opt/forem/config/forem.env and /opt/forem/version are ready."

