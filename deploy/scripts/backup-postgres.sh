#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/opt/forem/backups/postgres}"
DATABASE="${POSTGRES_DB:-forem_production}"
USER="${POSTGRES_USER:-forem}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="${BACKUP_DIR}/${DATABASE}-${STAMP}.dump"

install -d -m 0750 "$BACKUP_DIR"

docker compose --env-file /opt/forem/config/forem.env -f /opt/forem/compose.yml exec -T postgres pg_dump -U "$USER" -Fc "$DATABASE" > "$OUT"
gzip "$OUT"

find "$BACKUP_DIR" -type f -name '*.dump.gz' -mtime +30 -delete

echo "Created ${OUT}.gz"
