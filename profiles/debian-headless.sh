#!/usr/bin/env bash
set -euo pipefail

echo "[*] profile: debian-headless — update & essentials"
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  sudo curl wget ca-certificates vim htop ufw fail2ban

echo "[*] hardening: SSH"
SSH_CONFIG="/etc/ssh/sshd_config"
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
# Leave PasswordAuthentication as-is until you confirm key login works; then flip:
# sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
systemctl restart ssh || true

echo "[*] configuring: fail2ban (journald + UFW)"
install -d /etc/fail2ban/jail.d
cat >/etc/fail2ban/jail.d/sshd.local <<'EOF'
[DEFAULT]
backend  = systemd
banaction = ufw

[sshd]
enabled  = true
port     = ssh
logpath  = %(sshd_log)s
maxretry = 3
findtime = 10m
bantime  = 1h
EOF
systemctl enable --now fail2ban || true

echo "[*] configuring: UFW (deny-by-default)"
ufw --force reset >/dev/null 2>&1 || true
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

echo "[*] verify services"
systemctl is-active --quiet fail2ban && echo " - fail2ban: active ✅" || echo " - fail2ban: NOT active ❌"
systemctl is-active --quiet ssh      && echo " - sshd: active ✅"     || echo " - sshd: NOT active ❌"

echo "[*] profile: debian-headless — complete."
