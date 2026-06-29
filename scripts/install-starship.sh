#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
cw_parse_args "$@"
cw_load_config
cw_check_profile

if ! cw_command_exists starship; then
  if cw_confirm_sensitive CARACODERS_CONFIRM_STARSHIP_INSTALL "Install pinned Starship release binary?"; then
    version="${STARSHIP_VERSION:-v1.24.2}"
    case "$(uname -m)" in
    x86_64 | amd64)
      target="x86_64-unknown-linux-gnu"
      expected_sha="${STARSHIP_X86_64_GNU_SHA256:-3f12f61883ff324c1dbe7b885fa125d5490960e5cad6a12eeaa34695ec1b5744}"
      ;;
    *)
      cw_die "Starship pinned installer currently supports x86_64 only. Use manual installation for $(uname -m) after adding an approved checksum."
      ;;
    esac
    archive="starship-${target}.tar.gz"
    url="https://github.com/starship/starship/releases/download/${version}/${archive}"
    tmpdir="/tmp/caracoders-starship-${CW_STARTED_AT}"
    cw_run mkdir -p "$tmpdir"
    cw_download_file "$url" "$tmpdir/$archive"
    cw_verify_sha256 "$tmpdir/$archive" "$expected_sha"
    cw_run tar -xzf "$tmpdir/$archive" -C "$tmpdir" starship
    cw_install_binary_file "$tmpdir/starship" /usr/local/bin/starship 0755
    cw_run rm -rf "$tmpdir"
  else
    cw_warn "Starship install skipped."
  fi
else
  cw_log "Starship already installed: $(command -v starship)"
fi

cw_run mkdir -p "$HOME/.config"
cw_copy_with_backup "$CW_ROOT/config/starship/starship.toml" "$HOME/.config/starship.toml"

if [[ "${INSTALL_STARSHIP_FONT:-true}" == "true" ]]; then
  if cw_confirm_sensitive CARACODERS_CONFIRM_STARSHIP_FONT "Install FiraCode Nerd Font into ~/.local/share/fonts?"; then
    font_name="${NERD_FONT_NAME:-FiraCode}"
    font_version="${NERD_FONT_VERSION:-v3.4.0}"
    font_dir="$HOME/.local/share/fonts/${font_name}NerdFont"
    tmpdir="/tmp/caracoders-nerd-font-${CW_STARTED_AT}"
    font_zip="$tmpdir/${font_name}.zip"
    checksums="$tmpdir/SHA-256.txt"
    font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${font_version}/${font_name}.zip"
    checksums_url="${NERD_FONT_CHECKSUMS_URL:-https://github.com/ryanoasis/nerd-fonts/releases/download/${font_version}/SHA-256.txt}"
    cw_run mkdir -p "$tmpdir" "$font_dir"
    cw_download_file "$font_url" "$font_zip"
    cw_download_file "$checksums_url" "$checksums"
    cw_verify_sha256_from_manifest "$font_zip" "$checksums" "${font_name}.zip"
    cw_run unzip -o "$font_zip" -d "$font_dir"
    cw_run rm -rf "$tmpdir"
    cw_run fc-cache -f "$font_dir"
  fi
fi
