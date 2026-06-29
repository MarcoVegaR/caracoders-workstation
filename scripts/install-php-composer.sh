#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
cw_parse_args "$@"
cw_load_config
cw_check_profile

if ! cw_command_exists php; then
  cw_warn "PHP CLI not found. Installing Laravel apt package group first."
  cw_install_apt_file "$CW_ROOT/packages/apt-laravel.txt"
fi

if cw_command_exists composer; then
  cw_log "Composer already installed: $(command -v composer)"
  cw_run composer --version
else
  installer="/tmp/composer-setup-${CW_STARTED_AT}.php"
  cw_run php -r "copy('https://getcomposer.org/installer', '$installer');"
  if [[ "$CW_DRY_RUN" == "false" ]]; then
    expected="$(wget -q -O - https://composer.github.io/installer.sig)"
    actual="$(php -r "echo hash_file('sha384', '$installer');")"
    [[ "$expected" == "$actual" ]] || {
      rm -f "$installer"
      cw_die "Invalid Composer installer signature."
    }
  else
    cw_log "DRY-RUN: verify Composer installer signature"
  fi
  composer_version="${COMPOSER_VERSION:-2.10.1}"
  cw_run sudo php "$installer" --install-dir=/usr/local/bin --filename=composer --version="$composer_version"
  cw_run rm -f "$installer"
fi
