#!/usr/bin/env bash
set -euo pipefail

if ! command -v dnf >/dev/null 2>&1; then
  echo "This bootstrap is for Fedora/RHEL-family systems with dnf." >&2
  exit 1
fi

dnf update -y
dnf install -y git podman firewalld fail2ban vim tmux htop jq curl policycoreutils-python-utils caddy logrotate

systemctl enable --now firewalld
systemctl enable --now fail2ban

firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

if ! id deploy >/dev/null 2>&1; then
  useradd -m -s /bin/bash deploy
  usermod -aG wheel deploy
fi

install -d -m 0755 -o deploy -g deploy /opt/forem
for dir in backups config data postgres redis scripts systemd uploads; do
  install -d -m 0755 -o deploy -g deploy "/opt/forem/${dir}"
done

echo "Fedora bootstrap complete. Reboot is recommended if dnf updated kernel/system packages."

