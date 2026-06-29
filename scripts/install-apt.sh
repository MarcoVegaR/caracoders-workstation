#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
cw_parse_args "$@"
cw_load_config
cw_check_profile

package_file_for_module() {
  case "$1" in
  minimal) printf '%s\n' "$CW_ROOT/packages/apt-base.txt" ;;
  dev) printf '%s\n' "$CW_ROOT/packages/apt-dev.txt" ;;
  laravel) printf '%s\n' "$CW_ROOT/packages/apt-laravel.txt" ;;
  support) printf '%s\n' "$CW_ROOT/packages/apt-support.txt" ;;
  security) printf '%s\n' "$CW_ROOT/packages/apt-security.txt" ;;
  docker) printf '%s\n' "$CW_ROOT/packages/apt-docker.txt" ;;
  vscode | ai | devcontainer | starship | dotfiles) return 1 ;;
  *) cw_die "Unknown apt module: $1" ;;
  esac
}

installed_files=" "
while IFS= read -r module; do
  file="$(package_file_for_module "$module" || true)"
  [[ -z "${file:-}" ]] && continue
  [[ "$installed_files" == *" $file "* ]] && continue
  installed_files+="$file "
  cw_install_apt_file "$file"
done < <(cw_profile_modules "$CW_PROFILE")
