#!/usr/bin/env bash
set -euo pipefail
log()       { printf '[*] %s\n' "$*"; }
ensure_dir(){ install -d "$1"; }
