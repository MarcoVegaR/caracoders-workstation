#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
cw_parse_args "$@"
cw_load_config
cw_check_profile

cw_log "Preflight for profile: $CW_PROFILE"
[[ -r /etc/os-release ]] || cw_die "Cannot read /etc/os-release. Ubuntu real is required."
OS_ID=""
VERSION_ID=""
PRETTY_NAME=""
cw_load_key_value_file /etc/os-release "os-release"
[[ "${ID:-${OS_ID:-}}" == "ubuntu" ]] || cw_die "Unsupported OS: ${PRETTY_NAME:-unknown}. Ubuntu is required."
version="${VERSION_ID:-unknown}"
primary="${UBUNTU_PRIMARY:-26.04}"
secondary="${UBUNTU_SECONDARY:-24.04}"
[[ "$version" == "$primary" || "$version" == "$secondary" ]] || cw_die "Unsupported Ubuntu version: $version. Supported: $primary primary, $secondary secondary."
[[ -z "${WSL_DISTRO_NAME:-}" ]] || cw_die "WSL is out of scope for v1. Use real Ubuntu."
[[ "$(id -u)" -ne 0 ]] || cw_die "Do not run as root. Use a normal sudo-capable user."
cw_command_exists sudo || cw_die "sudo is required."
cw_log "OS OK: ${PRETTY_NAME:-Ubuntu}"
cw_log "User OK: $(id -un)"
cw_log "Dry-run: $CW_DRY_RUN | yes: $CW_YES | config: ${CW_CONFIG:-none}"
