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

profile_includes_module() {
  local wanted="$1" module
  while IFS= read -r module; do
    [[ "$module" == "$wanted" ]] && return 0
  done < <(cw_profile_modules "$CW_PROFILE")
  return 1
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
  starship) printf '%s\n' starship ;;
  devcontainer | dotfiles) : ;;
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
    current_user="$(id -un 2>/dev/null || printf '%s' "${USER:-unknown}")"
    current_groups="$(id -nG 2>/dev/null || true)"
    account_groups="$(id -nG "$current_user" 2>/dev/null || true)"
    if [[ " $account_groups " == *" docker "* && " $current_groups " != *" docker "* ]]; then
      cw_warn "Docker installed, and $current_user is in the docker group, but this session does not see that group yet. Run: newgrp docker; otherwise logout/login or reboot. Then re-run: ./doctor.sh --profile $CW_PROFILE --strict"
    elif [[ " $current_groups " == *" docker "* ]]; then
      cw_warn "Docker installed and this session has the docker group, but the daemon/socket is not reachable. Start Docker with: sudo systemctl enable --now docker; then run: docker info"
    else
      cw_warn "Docker installed, but $current_user is not in the docker group. Run: sudo usermod -aG docker $current_user; then run: newgrp docker; otherwise logout/login or reboot. Also ensure Docker is running: sudo systemctl enable --now docker"
    fi
    warn_count=$((warn_count + 1))
  fi
fi

if profile_includes_module starship && [[ "${INSTALL_STARSHIP_FONT:-true}" == "true" ]]; then
  font_name="${NERD_FONT_NAME:-FiraCode}"
  font_dir="$HOME/.local/share/fonts/${font_name}NerdFont"
  if [[ -d "$font_dir" ]] && compgen -G "$font_dir/*" >/dev/null; then
    printf 'OK   optional Nerd Font -> %s\n' "$font_dir"
  elif [[ "$CW_STRICT" == "true" ]]; then
    cw_warn "Optional ${font_name} Nerd Font not detected at $font_dir. Re-run scripts/install-starship.sh or set INSTALL_STARSHIP_FONT=false if this machine should not install it."
    warn_count=$((warn_count + 1))
  else
    printf 'INFO optional Nerd Font not detected at %s; bootstrap continues without this optional font unless --strict is used.\n' "$font_dir"
  fi
fi

if [[ "$CW_STRICT" == "true" && "$missing_count" -gt 0 ]]; then
  cw_die "Doctor strict failed: $missing_count required command(s) missing for profile $CW_PROFILE."
fi
if [[ "$CW_STRICT" == "true" && "$warn_count" -gt 0 ]]; then
  cw_die "Doctor strict failed: $warn_count warning(s) detected for profile $CW_PROFILE."
fi

cw_log "Doctor completed. Missing=$missing_count warnings=$warn_count. MISS entries are relevant to the selected profile only."
