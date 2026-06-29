#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
cw_parse_args "$@"
cw_load_config
cw_check_profile

export NVM_DIR="$HOME/.nvm"
if [[ ! -d "$NVM_DIR/.git" ]]; then
  cw_run git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
  cw_run git -C "$NVM_DIR" checkout "${NVM_VERSION:-v0.40.3}"
else
  cw_log "NVM already present at $NVM_DIR"
  cw_run git -C "$NVM_DIR" fetch --tags --quiet
  cw_run git -C "$NVM_DIR" checkout "${NVM_VERSION:-v0.40.3}"
fi

if [[ "$CW_DRY_RUN" == "false" ]]; then
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"
  nvm install "${NODE_VERSION:-24.17.0}"
  nvm alias default "${NODE_VERSION:-24.17.0}"
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    [[ "$pkg" == pnpm@* ]] || continue
    cw_run npm install -g "$pkg"
  done < "$CW_ROOT/packages/npm-global.txt"
else
  cw_log "DRY-RUN: source nvm and install Node ${NODE_VERSION:-24.17.0} plus pinned pnpm from packages/npm-global.txt"
fi
