#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
cw_parse_args "$@"
cw_load_config

cw_log "Manifest path: $CW_MANIFEST"
if [[ ! -f "$CW_MANIFEST" ]]; then
  cw_log "No install manifest found. Nothing to inspect."
  exit 0
fi

cw_log "This command is intentionally audit-first. It does not remove APT packages, repositories, Docker group membership, npm packages, Composer packages, fonts, VS Code config, OpenCode config, or MCP config automatically."
cw_log "Automatic reversal of those actions can break user-owned state and must be implemented per action class with explicit policy."

if [[ "$CW_DRY_RUN" == "true" ]]; then
  cw_log "DRY-RUN: would show recent manifest entries."
fi

tail -n 200 "$CW_MANIFEST"

cat <<'ROLLBACK_NOTES'

Suggested manual rollback checklist:
  1. Run ./scripts/rollback-dotfiles.sh to remove the marked .bashrc block.
  2. Review /etc/apt/sources.list.d/docker.list and /etc/apt/sources.list.d/vscode.list before deleting external repositories.
  3. Review npm global packages with: npm list -g --depth=0.
  4. Review Composer globals with: composer global show.
  5. Review ~/.config/opencode, ~/.config/Code/User, and ~/.local/share/fonts before removing user config.
  6. Review docker group membership with: groups "$USER".

No destructive rollback is performed by this script.
ROLLBACK_NOTES
