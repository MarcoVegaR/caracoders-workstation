#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
cw_parse_args "$@"
cw_load_config
cw_check_profile

cw_install_apt_file "$CW_ROOT/packages/apt-security.txt"

install_gitleaks() {
  if cw_command_exists gitleaks; then
    cw_warn "gitleaks already exists at $(command -v gitleaks); installing the Caracoders-approved checksum-verified version over /usr/local/bin/gitleaks."
  fi
  local version="${GITLEAKS_VERSION:-8.29.0}" arch asset url checksum_url tmpdir archive checksums
  case "$(uname -m)" in
  x86_64 | amd64) arch="x64" ;;
  aarch64 | arm64) arch="arm64" ;;
  *) cw_die "Unsupported architecture for gitleaks: $(uname -m)" ;;
  esac
  asset="gitleaks_${version}_linux_${arch}.tar.gz"
  url="https://github.com/gitleaks/gitleaks/releases/download/v${version}/${asset}"
  checksum_url="${GITLEAKS_CHECKSUMS_URL:-https://github.com/gitleaks/gitleaks/releases/download/v${version}/gitleaks_${version}_checksums.txt}"
  tmpdir="/tmp/caracoders-gitleaks-${CW_STARTED_AT}"
  archive="$tmpdir/$asset"
  checksums="$tmpdir/checksums.txt"
  cw_run mkdir -p "$tmpdir"
  cw_download_file "$url" "$archive"
  cw_download_file "$checksum_url" "$checksums"
  cw_verify_sha256_from_manifest "$archive" "$checksums" "$asset"
  cw_run tar -xzf "$archive" -C "$tmpdir" gitleaks
  cw_install_binary_file "$tmpdir/gitleaks" /usr/local/bin/gitleaks 0755
  cw_run rm -rf "$tmpdir"
}

install_trivy() {
  if cw_command_exists trivy; then
    cw_warn "trivy already exists at $(command -v trivy); installing the Caracoders-approved checksum-verified version over /usr/local/bin/trivy."
  fi
  local version="${TRIVY_VERSION:-0.71.2}" arch asset url checksum_url tmpdir archive checksums
  case "$(uname -m)" in
  x86_64 | amd64) arch="64bit" ;;
  aarch64 | arm64) arch="ARM64" ;;
  *) cw_die "Unsupported architecture for trivy: $(uname -m)" ;;
  esac
  asset="trivy_${version}_Linux-${arch}.tar.gz"
  url="https://github.com/aquasecurity/trivy/releases/download/v${version}/${asset}"
  checksum_url="${TRIVY_CHECKSUMS_URL:-https://github.com/aquasecurity/trivy/releases/download/v${version}/trivy_${version}_checksums.txt}"
  tmpdir="/tmp/caracoders-trivy-${CW_STARTED_AT}"
  archive="$tmpdir/$asset"
  checksums="$tmpdir/checksums.txt"
  cw_run mkdir -p "$tmpdir"
  cw_download_file "$url" "$archive"
  cw_download_file "$checksum_url" "$checksums"
  cw_verify_sha256_from_manifest "$archive" "$checksums" "$asset"
  cw_run tar -xzf "$archive" -C "$tmpdir" trivy
  cw_install_binary_file "$tmpdir/trivy" /usr/local/bin/trivy 0755
  cw_run rm -rf "$tmpdir"
}

install_hadolint() {
  if cw_command_exists hadolint; then
    cw_warn "hadolint already exists at $(command -v hadolint); installing the Caracoders-approved checksum-verified version over /usr/local/bin/hadolint."
  fi
  local version="${HADOLINT_VERSION:-2.14.0}" arch asset url checksum_url tmpdir bin sha_file expected
  case "$(uname -m)" in
  x86_64 | amd64)
    arch="x86_64"
    checksum_url="${HADOLINT_X86_64_SHA256_URL:-https://github.com/hadolint/hadolint/releases/download/v${version}/hadolint-linux-x86_64.sha256}"
    ;;
  aarch64 | arm64)
    arch="arm64"
    checksum_url="${HADOLINT_ARM64_SHA256_URL:-https://github.com/hadolint/hadolint/releases/download/v${version}/hadolint-linux-arm64.sha256}"
    ;;
  *) cw_die "Unsupported architecture for hadolint: $(uname -m)" ;;
  esac
  asset="hadolint-linux-${arch}"
  url="https://github.com/hadolint/hadolint/releases/download/v${version}/${asset}"
  tmpdir="/tmp/caracoders-hadolint-${CW_STARTED_AT}"
  bin="$tmpdir/hadolint"
  sha_file="$tmpdir/${asset}.sha256"
  cw_run mkdir -p "$tmpdir"
  cw_download_file "$url" "$bin"
  cw_download_file "$checksum_url" "$sha_file"
  if [[ "$CW_DRY_RUN" == "false" ]]; then
    expected="$(awk '{print $1; exit}' "$sha_file")"
    cw_verify_sha256 "$bin" "$expected"
  else
    cw_log "DRY-RUN: verify sha256 for $bin using $sha_file"
  fi
  cw_install_binary_file "$bin" /usr/local/bin/hadolint 0755
  cw_run rm -rf "$tmpdir"
}

install_gitleaks
install_trivy
install_hadolint

cw_run gitleaks version
cw_run trivy --version
cw_run hadolint --version
cw_log "Security profile installed local pinned CLI tools plus baseline apt tools. Downloaded release assets are checksum-verified before install."
