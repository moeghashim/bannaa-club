#!/usr/bin/env bash
set -euo pipefail

if ! command -v apt >/dev/null 2>&1; then
  echo "This bootstrap is for Ubuntu/Debian-family systems with apt." >&2
  exit 1
fi

apt update
apt upgrade -y
apt install -y git curl jq vim tmux htop fail2ban ufw ca-certificates caddy logrotate docker.io docker-compose-v2

systemctl enable --now fail2ban
systemctl enable --now docker

ufw allow OpenSSH
ufw allow http
ufw allow https
ufw --force enable

if ! id deploy >/dev/null 2>&1; then
  useradd -m -s /bin/bash deploy
  usermod -aG sudo deploy
fi

install -d -m 0755 -o deploy -g deploy /opt/forem
for dir in backups config data postgres redis scripts systemd uploads; do
  install -d -m 0755 -o deploy -g deploy "/opt/forem/${dir}"
done

echo "Ubuntu bootstrap complete. Reboot is recommended if apt updated kernel/system packages."
