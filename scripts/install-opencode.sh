#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
cw_parse_args "$@"
cw_load_config
cw_check_profile

cw_require_npm

package="$(cw_first_package_matching "$CW_ROOT/packages/npm-global.txt" 'opencode-ai@' || true)"
package="${package:-${OPENCODE_NPM_PACKAGE:-opencode-ai@1.17.11}}"
if cw_command_exists opencode; then
  cw_log "OpenCode already available: $(command -v opencode)"
  cw_run opencode --version
else
  cw_run npm install -g "$package"
fi

if cw_confirm_sensitive CARACODERS_CONFIRM_OPENCODE_CONFIG "Copy Caracoders OpenCode global config examples to ~/.config/opencode? Existing files get timestamped backups."; then
  cw_copy_tree_with_backup "$CW_ROOT/config/opencode" "$HOME/.config/opencode"
  cw_record_action "COPY_TREE_WITH_BACKUP config/opencode -> $HOME/.config/opencode"
  cw_warn "No API keys were copied. Configure provider credentials outside this repository."
fi
