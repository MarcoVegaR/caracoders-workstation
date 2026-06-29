#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
cw_parse_args "$@"
cw_load_config

bashrc="$HOME/.bashrc"
block_start="# >>> caracoders-workstation >>>"
block_end="# <<< caracoders-workstation <<<"
[[ -f "$bashrc" ]] || {
  cw_log "No .bashrc found. Nothing to rollback."
  exit 0
}
grep -Fq "$block_start" "$bashrc" || {
  cw_log "No Caracoders block found in .bashrc. Nothing to rollback."
  exit 0
}

if cw_confirm_sensitive CARACODERS_CONFIRM_ROLLBACK_DOTFILES "Remove Caracoders marked block from .bashrc?"; then
  cw_backup_file "$bashrc"
  if [[ "$CW_DRY_RUN" == "false" ]]; then
    python3 - "$bashrc" "$block_start" "$block_end" <<'PYROLLBACK'
from pathlib import Path
import sys
path = Path(sys.argv[1])
start = sys.argv[2]
end = sys.argv[3]
lines = path.read_text().splitlines()
out = []
skip = False
for line in lines:
    if line.strip() == start:
        skip = True
        continue
    if skip and line.strip() == end:
        skip = False
        continue
    if not skip:
        out.append(line)
path.write_text("\n".join(out).rstrip() + "\n")
PYROLLBACK
    cw_record_action "ROLLBACK caracoders block from $bashrc"
  else
    cw_log "DRY-RUN: remove marked block from $bashrc"
  fi
fi
