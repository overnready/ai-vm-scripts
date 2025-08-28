#!/usr/bin/env bash
set -euo pipefail

echo "[*] profile: debian-headless — update & essentials"
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  sudo curl wget ca-certificates vim htop ufw fail2ban python3-systemd

echo "[*] hardening: SSH"
SSH_CONFIG="/etc/ssh/sshd_config"
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
# Leave PasswordAuthentication as-is until you confirm key login works; then flip:
# sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
systemctl restart ssh || true

echo "[*] configuring: fail2ban (journald + UFW)"
# Wipe any previous configs
rm -rf /etc/fail2ban/jail.d/*
# Main jail.local for journald backend
cat >/etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
backend   = systemd
banaction = ufw
ignoreip  = 127.0.0.1/8 ::1

[sshd]
enabled   = true
port      = ssh
maxretry  = 3
findtime  = 10m
bantime   = 1h
EOF

# Ensure runtime dir exists (Debian bug workaround)
rm -rf /run/fail2ban
install -d -m 755 /run/fail2ban

systemctl enable --now fail2ban || true
systemctl restart fail2ban || true

echo "[*] configuring: UFW (deny-by-default)"
ufw --force reset >/dev/null 2>&1 || true
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP (optional)
ufw allow 443/tcp  # HTTPS (optional)
# Do NOT 'ufw enable' here — Packer HCL does it safely at the end.

echo "[*] configuring: primary network interface"
# Detect default IPv4 interface dynamically (works for ens3, enp0s3, eth0, etc.)
IFACE="$(ip -o -4 route show to default | awk '{print $5; exit}' || true)"
if [ -n "${IFACE:-}" ]; then
  echo " - detected default interface: $IFACE"

  mkdir -p /etc/network/interfaces.d

  # Ensure ifupdown reads interfaces.d
  grep -q '^source-directory /etc/network/interfaces.d' /etc/network/interfaces || \
    printf 'source-directory /etc/network/interfaces.d\n' >> /etc/network/interfaces

  # Drop a clean config for the primary interface
  cat > /etc/network/interfaces.d/primary.cfg <<EOF
auto $IFACE
allow-hotplug $IFACE
iface $IFACE inet dhcp
EOF

  echo " - wrote /etc/network/interfaces.d/primary.cfg"
else
  echo " - WARNING: no default interface detected!"
fi


echo "[*] verify services"
systemctl is-active --quiet fail2ban && echo " - fail2ban: active ✅" || echo " - fail2ban: NOT active ❌"
systemctl is-active --quiet ssh      && echo " - sshd: active ✅"     || echo " - sshd: NOT active ❌"

echo "[*] profile: debian-headless — complete."

