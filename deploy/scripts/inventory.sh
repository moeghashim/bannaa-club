#!/usr/bin/env bash
set -euo pipefail

echo "== identity =="
id
whoami
hostname || true

echo
echo "== os =="
hostnamectl || true
cat /etc/os-release || true
uname -a

echo
echo "== cpu/memory/disk =="
lscpu || true
free -h || true
df -h || true
lsblk || true

echo
echo "== network =="
ip addr || true
ss -tulpn || true

echo
echo "== failed systemd units =="
systemctl --failed || true

echo
echo "== running services =="
systemctl list-units --type=service --state=running || true

echo
echo "== containers =="
podman --version || true
podman ps -a || true
docker --version || true
docker ps -a || true
docker compose version || true

echo
echo "== common app directories =="
ls -la /opt || true
ls -la /srv || true
ls -la /var/www || true
ls -la /home || true

echo
echo "== scheduled jobs =="
crontab -l || true
ls -la /etc/cron.d || true

echo
echo "== package updates =="
if command -v dnf >/dev/null 2>&1; then
  dnf check-update || true
elif command -v apt >/dev/null 2>&1; then
  apt update >/dev/null
  apt list --upgradable || true
fi

