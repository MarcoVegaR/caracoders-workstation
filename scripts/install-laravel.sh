#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
cw_parse_args "$@"
cw_load_config
cw_check_profile

if ! cw_command_exists composer; then
  if [[ "$CW_DRY_RUN" == "true" ]]; then
    cw_log "DRY-RUN: Composer is required before installing Laravel Installer."
  else
    cw_die "Composer is required before installing Laravel Installer."
  fi
fi

package="$(cw_first_package_matching "$CW_ROOT/packages/composer-global.txt" 'laravel/installer' || true)"
package="${package:-laravel/installer:${LARAVEL_INSTALLER_CONSTRAINT:-^5.26}}"
if cw_command_exists laravel; then
  cw_log "Laravel Installer already available: $(command -v laravel)"
  cw_run laravel --version
else
  cw_run composer global require "$package"
  cw_warn "Ensure Composer global bin is in PATH. link-dotfiles.sh manages this through the marked bash block."
fi
