#!/bin/bash
set -euo pipefail

# 1. Update base system
apt-get update -y
apt-get install -y --no-install-recommends git ca-certificates

# 2. Clone repo
REPO_URL="https://github.com/youruser/vm-scripts.git"
CLONE_DIR="/opt/vm-scripts"
rm -rf "$CLONE_DIR"
git clone "$REPO_URL" "$CLONE_DIR"

# 3. Detect profile
PROFILE="${PROFILE:-default}"
echo "Using profile: $PROFILE"

# 4. Run profile script
cd "$CLONE_DIR/profiles"
if [[ -x "$PROFILE.sh" ]]; then
  echo "Running profile script: $PROFILE.sh"
  bash "$PROFILE.sh"
else
  echo "ERROR: Profile $PROFILE.sh not found!"
  exit 1
fi

# 5. Done
echo "Bootstrap finished successfully!"
