#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
cw_parse_args "$@"
cw_load_config
cw_check_profile

cw_log "Update requested for profile=$CW_PROFILE"
if [[ -d "$CW_ROOT/.git" ]]; then
  if cw_confirm "Pull latest repository changes before updating workstation?"; then
    cw_run git -C "$CW_ROOT" pull --ff-only
  fi
else
  cw_warn "Not a git checkout; skipping git pull."
fi

args=(--profile "$CW_PROFILE")
[[ "$CW_DRY_RUN" == "true" ]] && args+=(--dry-run)
[[ "$CW_YES" == "true" ]] && args+=(--yes)
[[ -n "$CW_CONFIG" ]] && args+=(--config "$CW_CONFIG")
"$CW_ROOT/scripts/bootstrap.sh" "${args[@]}"
