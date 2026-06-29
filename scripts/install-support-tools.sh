#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
cw_parse_args "$@"; cw_load_config; cw_check_profile
cw_install_apt_file "$CW_ROOT/packages/apt-support.txt"
if cw_confirm_sensitive CARACODERS_CONFIRM_ANYDESK "Install AnyDesk for support use? No unattended access will be configured."; then cw_warn "AnyDesk installation is intentionally not implemented in v1. Add a reviewed installer only after policy approval."; fi
