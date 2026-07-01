#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
cw_parse_args "$@"
cw_load_config
cw_check_profile
cw_load_nvm_if_available
export PATH="$HOME/.config/composer/vendor/bin:$HOME/.composer/vendor/bin:$PATH"

missing_count=0
warn_count=0

check_cmd() {
  local cmd="$1"
  if cw_command_exists "$cmd"; then
    printf 'OK   %s -> %s\n' "$cmd" "$(command -v "$cmd")"
  else
    printf 'MISS %s\n' "$cmd"
    missing_count=$((missing_count + 1))
  fi
}

required_commands_for_module() {
  case "$1" in
  minimal) printf '%s\n' git curl jq tree htop ;;
  dev) printf '%s\n' gh rg fdfind fzf batcat eza btop ncdu make shellcheck shfmt pre-commit http python3 pipx yq ;;
  laravel) printf '%s\n' php composer laravel node npm pnpm psql redis-cli ;;
  docker) printf '%s\n' docker ;;
  vscode) printf '%s\n' code ;;
  ai) printf '%s\n' git python3 node npm npx opencode ;;
  support) printf '%s\n' dig whois traceroute ip iperf3 http jq remmina flameshot smartctl gnome-disks ncdu lsof rsync filezilla ;;
  security) printf '%s\n' gitleaks trivy hadolint shellcheck shfmt pre-commit ;;
  devcontainer | starship | dotfiles) : ;;
  esac
}

cw_log "Doctor profile=$CW_PROFILE strict=$CW_STRICT"
seen=" "
while IFS= read -r module; do
  while IFS= read -r cmd; do
    [[ -z "$cmd" ]] && continue
    [[ "$seen" == *" $cmd "* ]] && continue
    seen+="$cmd "
    check_cmd "$cmd"
  done < <(required_commands_for_module "$module")
done < <(cw_profile_modules "$CW_PROFILE")

if cw_command_exists docker; then
  if docker info >/dev/null 2>&1; then
    cw_log "Docker daemon reachable"
  else
    user_groups="$(id -nG "$USER" 2>/dev/null || true)"
    if [[ " $user_groups " == *" docker "* ]]; then
      cw_warn "Docker installed but daemon not reachable for current user. If group membership was just changed, logout/login, reboot, or run 'newgrp docker'; otherwise start Docker with: sudo systemctl enable --now docker"
    else
      cw_warn "Docker installed but daemon not reachable for current user. Run: sudo usermod -aG docker $USER, then logout/login, reboot, or run 'newgrp docker'. Also ensure Docker is running: sudo systemctl enable --now docker"
    fi
    warn_count=$((warn_count + 1))
  fi
fi

if [[ "$CW_STRICT" == "true" && "$missing_count" -gt 0 ]]; then
  cw_die "Doctor strict failed: $missing_count required command(s) missing for profile $CW_PROFILE."
fi
if [[ "$CW_STRICT" == "true" && "$warn_count" -gt 0 ]]; then
  cw_die "Doctor strict failed: $warn_count warning(s) detected for profile $CW_PROFILE."
fi

cw_log "Doctor completed. Missing=$missing_count warnings=$warn_count. MISS entries are relevant to the selected profile only."
