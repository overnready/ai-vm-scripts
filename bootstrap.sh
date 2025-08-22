#!/usr/bin/env bash
set -euo pipefail

# Which profile to run (set by Packer env: PROFILE=debian-headless, etc.)
PROFILE="${PROFILE:-debian-headless}"

# Assume Packer cloned repo to /opt/ai-vm-scripts; fall back to script’s own dir
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="${REPO_DIR:-/opt/ai-vm-scripts}"
[ -d "$REPO_DIR" ] || REPO_DIR="$BASE_DIR"

PROFILE_SCRIPT="$REPO_DIR/profiles/${PROFILE}.sh"

echo "[*] bootstrap: using repo dir: $REPO_DIR"
echo "[*] bootstrap: profile: $PROFILE"

if [[ ! -x "$PROFILE_SCRIPT" ]]; then
  echo "ERROR: profile not found or not executable: $PROFILE_SCRIPT"
  exit 1
fi

exec bash "$PROFILE_SCRIPT"
