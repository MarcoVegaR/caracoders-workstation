#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
cw_parse_args "$@"
cw_load_config
cw_check_profile

config_dir="$HOME/.config/caracoders-workstation/bash"
cw_run mkdir -p "$config_dir"
cw_run install -m 0644 "$CW_ROOT/dotfiles/bash/path.sh" "$config_dir/path.sh"
cw_run install -m 0644 "$CW_ROOT/dotfiles/bash/caracoders-workstation.sh" "$config_dir/caracoders-workstation.sh"

bashrc="$HOME/.bashrc"
block_start="# >>> caracoders-workstation >>>"
block_end="# <<< caracoders-workstation <<<"
block="${block_start}
source \"$HOME/.config/caracoders-workstation/bash/caracoders-workstation.sh\"
${block_end}"

if [[ -f "$bashrc" ]] && grep -Fq "$block_start" "$bashrc"; then
  cw_log ".bashrc already contains Caracoders block"
else
  if cw_confirm_sensitive CARACODERS_CONFIRM_BASHRC_BLOCK "Modify .bashrc with marked reversible Caracoders block?"; then
    [[ -f "$bashrc" ]] || cw_run touch "$bashrc"
    cw_backup_file "$bashrc"
    if [[ "$CW_DRY_RUN" == "false" ]]; then
      printf '\n%s\n' "$block" >> "$bashrc"
      cw_record_action "APPEND caracoders block to $bashrc"
    else
      cw_log "DRY-RUN: append marked block to $bashrc"
    fi
  fi
fi

if [[ -n "${GIT_AUTHOR_NAME:-}" || -n "${GIT_AUTHOR_EMAIL:-}" ]]; then
  if cw_confirm_sensitive CARACODERS_CONFIRM_GITCONFIG "Configure global Git user.name/user.email?"; then
    [[ -n "${GIT_AUTHOR_NAME:-}" ]] && cw_run git config --global user.name "$GIT_AUTHOR_NAME"
    [[ -n "${GIT_AUTHOR_EMAIL:-}" ]] && cw_run git config --global user.email "$GIT_AUTHOR_EMAIL"
  fi
elif [[ "$CW_YES" == "false" && "$CW_DRY_RUN" == "false" ]]; then
  cw_log "Git identity not provided. Skipping global git config."
fi
