#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

usage() {
  cat <<'USAGE'
caracoders-workstation bootstrap

Examples:
  ./bootstrap.sh --profile full --dry-run
  ./bootstrap.sh --profile full
  ./bootstrap.sh --profile full --yes --config ./.caracoders-workstation.env
USAGE
  cw_usage_common
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && {
  usage
  exit 0
}
cw_parse_args "$@"
cw_load_config
cw_check_profile

run_script() {
  local script="$1"
  shift || true
  local args=("$@")
  [[ "$CW_DRY_RUN" == "true" ]] && args+=(--dry-run)
  [[ "$CW_YES" == "true" ]] && args+=(--yes)
  [[ -n "$CW_CONFIG" ]] && args+=(--config "$CW_CONFIG")
  cw_log "==> $script $(cw_quote_cmd "${args[@]}")"
  "$CW_ROOT/scripts/$script" "${args[@]}"
}

run_module() {
  local module="$1"
  case "$module" in
  minimal) : ;;
  dev)
    run_script install-node-nvm.sh --profile "$CW_PROFILE"
    run_script link-dotfiles.sh --profile "$CW_PROFILE"
    ;;
  laravel)
    run_script install-node-nvm.sh --profile "$CW_PROFILE"
    run_script install-php-composer.sh --profile "$CW_PROFILE"
    run_script install-laravel.sh --profile "$CW_PROFILE"
    run_script link-dotfiles.sh --profile "$CW_PROFILE"
    ;;
  docker) run_script install-docker.sh --profile "$CW_PROFILE" ;;
  devcontainer) cw_log "Dev Container templates are repository assets; no host install needed beyond Docker + VS Code extension." ;;
  vscode) run_script install-vscode.sh --profile "$CW_PROFILE" ;;
  ai)
    run_script install-node-nvm.sh --profile "$CW_PROFILE"
    run_script install-opencode.sh --profile "$CW_PROFILE"
    run_script install-mcp.sh --profile "$CW_PROFILE"
    ;;
  support) run_script install-support-tools.sh --profile "$CW_PROFILE" ;;
  security) run_script install-security-tools.sh --profile "$CW_PROFILE" ;;
  starship) run_script install-starship.sh --profile "$CW_PROFILE" ;;
  dotfiles) run_script link-dotfiles.sh --profile "$CW_PROFILE" ;;
  *) cw_die "Unknown profile module: $module" ;;
  esac
}

cw_log "Starting bootstrap. profile=$CW_PROFILE dry-run=$CW_DRY_RUN yes=$CW_YES"
run_script preflight.sh --profile "$CW_PROFILE"
run_script install-apt.sh --profile "$CW_PROFILE"
while IFS= read -r module; do
  run_module "$module"
done < <(cw_profile_modules "$CW_PROFILE")
run_script doctor.sh --profile "$CW_PROFILE"
run_script verify.sh --profile "$CW_PROFILE"
cw_log "Bootstrap finished. Review warnings above. Docker group changes may require logout/login."
