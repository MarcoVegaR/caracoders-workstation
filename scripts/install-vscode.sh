#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
cw_parse_args "$@"
cw_load_config
cw_check_profile

if ! cw_command_exists code; then
  if cw_confirm_sensitive CARACODERS_ALLOW_VSCODE_APT_REPO "Add Microsoft VS Code APT repository and install VS Code?"; then
    repo_line="deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main"
    cw_run sudo apt-get update
    cw_run sudo apt-get install -y wget gpg apt-transport-https
    cw_run mkdir -p /tmp/caracoders-workstation
    cw_run wget -qO /tmp/caracoders-workstation/microsoft.asc https://packages.microsoft.com/keys/microsoft.asc
    if [[ "$CW_DRY_RUN" == "false" ]]; then
      gpg --dearmor </tmp/caracoders-workstation/microsoft.asc >/tmp/caracoders-workstation/packages.microsoft.gpg
      cw_record_action "CREATE /tmp/caracoders-workstation/packages.microsoft.gpg"
    else
      cw_log "DRY-RUN: dearmor Microsoft signing key"
    fi
    cw_run sudo install -D -o root -g root -m 0644 /tmp/caracoders-workstation/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    cw_sudo_write_file /etc/apt/sources.list.d/vscode.list "$repo_line"
    cw_run rm -rf /tmp/caracoders-workstation
    cw_run sudo apt-get update
    cw_run sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y code
  else
    cw_warn "VS Code installation skipped."
  fi
else
  cw_log "VS Code already installed: $(command -v code)"
fi

if cw_command_exists code; then
  cw_log "Recommended VS Code extensions:"
  sed 's/^/  - /' "$CW_ROOT/config/vscode/extensions.recommended.txt"
  install_ext="false"
  if [[ "${INSTALL_VSCODE_EXTENSIONS:-true}" == "true" ]]; then
    if [[ "$CW_YES" == "true" || "$CW_DRY_RUN" == "true" ]]; then
      install_ext="true"
    elif cw_confirm "Install recommended VS Code extensions?"; then
      install_ext="true"
    fi
  fi
  if [[ "$install_ext" == "true" ]]; then
    while IFS= read -r ext; do
      [[ -z "$ext" || "$ext" =~ ^# ]] && continue
      cw_run code --install-extension "$ext" --force
    done <"$CW_ROOT/config/vscode/extensions.recommended.txt"
  fi
  if cw_confirm_sensitive CARACODERS_CONFIRM_COPY_VSCODE_CONFIG "Copy global VS Code settings.json to user profile?"; then
    cw_copy_with_backup "$CW_ROOT/config/vscode/settings.json" "$HOME/.config/Code/User/settings.json"
  fi
fi
