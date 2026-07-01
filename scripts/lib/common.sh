#!/usr/bin/env bash
# shellcheck disable=SC2034
set -Eeuo pipefail

CW_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CW_SCRIPTS_DIR="$(cd "$CW_COMMON_DIR/.." && pwd)"
CW_ROOT="$(cd "$CW_SCRIPTS_DIR/.." && pwd)"
CW_PROFILE="minimal"
CW_DRY_RUN="false"
CW_YES="false"
CW_STRICT="false"
CW_CONFIG=""
CW_STARTED_AT="$(date +%Y%m%d-%H%M%S)"
CW_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/caracoders-workstation"
CW_MANIFEST="$CW_STATE_DIR/install-manifest.log"

cw_log() { printf '[caracoders] %s\n' "$*"; }
cw_warn() { printf '[caracoders][WARN] %s\n' "$*" >&2; }
cw_err() { printf '[caracoders][ERROR] %s\n' "$*" >&2; }
cw_die() {
  cw_err "$*"
  exit 1
}

cw_usage_common() {
  cat <<'USAGE'
Common options:
  --profile <name>       minimal|dev|laravel|docker|devcontainer|vscode|ai|support|security|full
  --dry-run              Print intended actions without changing the system
  --yes                  Non-interactive mode; sensitive actions still require explicit config consent
  --config <file>        Load ignored local config file using safe allowlisted KEY=VALUE parsing
  --strict               Fail on warnings/missing checks where supported by the script
  --help                 Show help
USAGE
}

cw_parse_args() {
  while (($#)); do
    case "$1" in
    --profile)
      [[ $# -ge 2 ]] || cw_die "--profile requires a value"
      CW_PROFILE="$2"
      shift 2
      ;;
    --profile=*)
      CW_PROFILE="${1#*=}"
      shift
      ;;
    --dry-run)
      CW_DRY_RUN="true"
      shift
      ;;
    --yes | -y)
      CW_YES="true"
      shift
      ;;
    --strict)
      CW_STRICT="true"
      shift
      ;;
    --config)
      [[ $# -ge 2 ]] || cw_die "--config requires a file"
      CW_CONFIG="$2"
      shift 2
      ;;
    --config=*)
      CW_CONFIG="${1#*=}"
      shift
      ;;
    --help | -h)
      cw_usage_common
      exit 0
      ;;
    *) cw_die "Unknown argument: $1" ;;
    esac
  done
}

cw_trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

cw_strip_inline_comment() {
  local line="$1" out="" ch in_single="false" in_double="false" i
  for ((i = 0; i < ${#line}; i++)); do
    ch="${line:i:1}"
    if [[ "$ch" == "'" && "$in_double" == "false" ]]; then
      if [[ "$in_single" == "true" ]]; then in_single="false"; else in_single="true"; fi
      out+="$ch"
      continue
    fi
    if [[ "$ch" == '"' && "$in_single" == "false" ]]; then
      if [[ "$in_double" == "true" ]]; then in_double="false"; else in_double="true"; fi
      out+="$ch"
      continue
    fi
    if [[ "$ch" == "#" && "$in_single" == "false" && "$in_double" == "false" ]]; then
      break
    fi
    out+="$ch"
  done
  printf '%s' "$out"
}

cw_key_is_dangerous() {
  local key="$1"
  case "$key" in
  PATH | IFS | BASH_ENV | ENV | SHELLOPTS | BASHOPTS | CDPATH | GLOBIGNORE | PROMPT_COMMAND | PS4 | HOME | USER | UID | EUID | PWD | OLDPWD | RANDOM | LINENO | SECONDS | HISTFILE | HISTCONTROL | HISTIGNORE | LD_* | DYLD_* | SUDO_* | CW_*) return 0 ;;
  *) return 1 ;;
  esac
}

cw_config_key_allowed() {
  local key="$1" label="$2"

  if cw_key_is_dangerous "$key"; then
    return 1
  fi

  case "$label" in
  versions)
    case "$key" in
    UBUNTU_PRIMARY | UBUNTU_SECONDARY | NODE_VERSION | NVM_VERSION | PHP_VERSION_POLICY | COMPOSER_VERSION | LARAVEL_INSTALLER_CONSTRAINT | DOCKER_CHANNEL | DOCKER_APT_KEY_URL | DOCKER_APT_KEY_FINGERPRINT | OPENCODE_NPM_PACKAGE | MCP_FILESYSTEM_PACKAGE | MCP_PLAYWRIGHT_PACKAGE | MCP_CONTEXT7_PACKAGE | MCP_POSTGRES_PACKAGE | PNPM_PACKAGE | NERD_FONT_NAME | NERD_FONT_VERSION | DOCKER_HELLO_WORLD_IMAGE | GITLEAKS_VERSION | TRIVY_VERSION | HADOLINT_VERSION | STARSHIP_VERSION | STARSHIP_X86_64_GNU_SHA256 | PECL_REDIS_VERSION | GITLEAKS_CHECKSUMS_URL | TRIVY_CHECKSUMS_URL | HADOLINT_X86_64_SHA256_URL | HADOLINT_ARM64_SHA256_URL | NERD_FONT_SHA256 | NERD_FONT_CHECKSUMS_URL) return 0 ;;
    *) return 1 ;;
    esac
    ;;
  profile)
    case "$key" in
    PROFILE_NAME | PROFILE_MODULES) return 0 ;;
    *) return 1 ;;
    esac
    ;;
  os-release)
    # /etc/os-release is trusted system metadata and varies by distro/version.
    # Dangerous shell/environment keys are still blocked by cw_key_is_dangerous above.
    return 0
    ;;
  local-config)
    case "$key" in
    CARACODERS_USER_NAME | CARACODERS_USER_EMAIL | GIT_AUTHOR_NAME | GIT_AUTHOR_EMAIL | GITHUB_USERNAME | OPENCODE_PROVIDER | OPENCODE_API_KEY | MCP_FILESYSTEM_ALLOW_HOME | MCP_FILESYSTEM_ALLOWED_PATHS | INSTALL_VSCODE_EXTENSIONS | INSTALL_STARSHIP_FONT | CARACODERS_CONFIRM_* | CARACODERS_ALLOW_*) return 0 ;;
    PROFILE_* | CW_*) return 1 ;;
    *) return 1 ;;
    esac
    ;;
  *)
    return 1
    ;;
  esac
}

cw_normalize_config_label() {
  local label="$1"
  case "$label" in
  versions | profile | os-release) printf '%s' "$label" ;;
  local\ config | local-config) printf 'local-config' ;;
  *) printf '%s' "$label" ;;
  esac
}

cw_load_key_value_file() {
  local file="$1" raw_label="${2:-local-config}" label line key value n
  label="$(cw_normalize_config_label "$raw_label")"
  [[ -f "$file" ]] || cw_die "Config file not found: $file"
  n=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    n=$((n + 1))
    line="$(cw_trim "$(cw_strip_inline_comment "$line")")"
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] || cw_die "Invalid $raw_label line $n in $file. Use simple KEY=VALUE only."
    key="${line%%=*}"
    value="${line#*=}"
    key="$(cw_trim "$key")"
    value="$(cw_trim "$value")"

    if ! cw_config_key_allowed "$key" "$label"; then
      cw_die "Forbidden or unsupported key '$key' in $file line $n for $raw_label. Local config uses an allowlist."
    fi

    [[ "$value" != *'$('* ]] || cw_die "Command substitution is forbidden in $file line $n."
    [[ "$value" != *'`'* ]] || cw_die "Backticks are forbidden in $file line $n."
    [[ "$value" != *';'* ]] || cw_die "Semicolons are forbidden in $file line $n."
    [[ "$value" != *$'\n'* ]] || cw_die "Newlines are forbidden in $file line $n."

    if [[ "$value" == \"*\" && "$value" == *\" ]]; then
      value="${value:1:${#value}-2}"
    elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
      value="${value:1:${#value}-2}"
    fi

    value="${value//\$\{HOME\}/$HOME}"
    value="${value//\$HOME/$HOME}"
    [[ "$value" == ~/* ]] && value="$HOME/${value#~/}"
    declare -gx "$key=$value"
  done <"$file"
}

cw_load_config() {
  [[ -f "$CW_ROOT/config/versions.env" ]] && cw_load_key_value_file "$CW_ROOT/config/versions.env" "versions"
  if [[ -n "$CW_CONFIG" ]]; then
    [[ -f "$CW_CONFIG" ]] || cw_die "Config file not found: $CW_CONFIG"
    case "$CW_CONFIG" in
    *.example) cw_die "Do not use example config as real config: $CW_CONFIG" ;;
    esac
    cw_load_key_value_file "$CW_CONFIG" "local-config"
  fi
}

cw_check_profile() {
  case "$CW_PROFILE" in
  minimal | dev | laravel | docker | devcontainer | vscode | ai | support | security | full) ;;
  *) cw_die "Unsupported profile: $CW_PROFILE" ;;
  esac
}

cw_load_profile_config() {
  local profile="${1:-$CW_PROFILE}"
  local file="$CW_ROOT/config/profiles/${profile}.env"
  [[ -f "$file" ]] || cw_die "Profile config not found: $file"
  PROFILE_NAME=""
  PROFILE_MODULES=""
  cw_load_key_value_file "$file" "profile"
  [[ -n "${PROFILE_MODULES:-}" ]] || cw_die "PROFILE_MODULES missing in $file"
}

cw_profile_modules() {
  local profile="${1:-$CW_PROFILE}"
  cw_load_profile_config "$profile"
  # shellcheck disable=SC2206
  local modules=(${PROFILE_MODULES})
  local seen=" " module
  for module in "${modules[@]}"; do
    [[ "$seen" == *" $module "* ]] && continue
    printf '%s\n' "$module"
    seen+="$module "
  done
}

cw_command_exists() { command -v "$1" >/dev/null 2>&1; }

cw_load_nvm_if_available() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
    if command -v nvm >/dev/null 2>&1; then
      nvm use "${NODE_VERSION:-24.17.0}" >/dev/null 2>&1 || nvm use default >/dev/null 2>&1 || true
    fi
  fi
}

cw_require_npm() {
  if ! cw_command_exists npm; then
    cw_load_nvm_if_available
  fi
  if ! cw_command_exists npm; then
    if [[ "$CW_DRY_RUN" == "true" ]]; then
      cw_log "DRY-RUN: npm is required and would be provided by install-node-nvm.sh."
      return 0
    fi
    cw_die "npm is required but was not found. Run install-node-nvm.sh or ensure NVM default Node is active."
  fi
}

cw_quote_cmd() {
  local quoted="" arg
  for arg in "$@"; do
    printf -v arg '%q' "$arg"
    quoted+="${quoted:+ }$arg"
  done
  printf '%s' "$quoted"
}

cw_record_action() {
  local message="$1"
  [[ "$CW_DRY_RUN" == "true" ]] && return 0
  mkdir -p "$CW_STATE_DIR"
  printf '%s %s\n' "$(date -Is)" "$message" >>"$CW_MANIFEST"
}

cw_run() {
  (($# > 0)) || cw_die "cw_run requires a command"
  local display
  display="$(cw_quote_cmd "$@")"
  if [[ "$CW_DRY_RUN" == "true" ]]; then
    cw_log "DRY-RUN: $display"
  else
    cw_log "RUN: $display"
    cw_record_action "RUN $display"
    "$@"
  fi
}

cw_sudo_write_file() {
  local dst="$1" content="$2"
  if [[ "$CW_DRY_RUN" == "true" ]]; then
    cw_log "DRY-RUN: write root-owned file $dst"
  else
    cw_log "RUN: write root-owned file $dst"
    cw_record_action "WRITE $dst"
    printf '%s\n' "$content" | sudo tee "$dst" >/dev/null
  fi
}

cw_confirm() {
  local prompt="$1"
  if [[ "$CW_DRY_RUN" == "true" ]]; then
    cw_log "DRY-RUN confirmation skipped: $prompt"
    return 0
  fi
  if [[ "$CW_YES" == "true" ]]; then
    return 0
  fi
  local reply
  if ! printf '%s [y/N]: ' "$prompt" 2>/dev/null >/dev/tty; then
    cw_warn "No interactive terminal available; skipping confirmation: $prompt"
    return 1
  fi
  if ! IFS= read -r reply 2>/dev/null </dev/tty; then
    cw_warn "No confirmation received from interactive terminal; skipping: $prompt"
    return 1
  fi
  [[ "$reply" =~ ^[Yy]$ ]]
}

cw_confirm_sensitive() {
  local env_key="$1" prompt="$2"
  if [[ "$CW_DRY_RUN" == "true" ]]; then
    if [[ "$CW_YES" == "true" ]]; then
      local value="${!env_key:-false}"
      if [[ "$value" == "true" ]]; then
        cw_log "DRY-RUN sensitive action would be approved by config: $env_key=true"
      else
        cw_log "DRY-RUN sensitive action would be skipped in --yes mode unless $env_key=true: $prompt"
        return 1
      fi
    else
      cw_log "DRY-RUN sensitive confirmation required at runtime: $prompt"
    fi
    return 0
  fi
  if [[ "$CW_YES" == "true" ]]; then
    local value="${!env_key:-false}"
    if [[ "$value" == "true" ]]; then
      cw_log "Sensitive action approved by config: $env_key=true"
      return 0
    fi
    cw_warn "Skipping sensitive action in --yes mode because $env_key is not true"
    return 1
  fi
  cw_confirm "$prompt"
}

cw_backup_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    local backup="$file.caracoders-backup-$CW_STARTED_AT"
    cw_run cp "$file" "$backup"
    cw_log "Backup prepared: $backup"
  fi
}

cw_read_package_file() {
  local file="$1"
  [[ -f "$file" ]] || cw_die "Package file not found: $file"
  grep -Ev '^\s*($|#)' "$file" || true
}

cw_first_package_matching() {
  local file="$1" prefix="$2" line
  while IFS= read -r line; do
    [[ "$line" == "$prefix"* ]] || continue
    printf '%s\n' "$line"
    return 0
  done < <(cw_read_package_file "$file")
  return 1
}

cw_install_apt_file() {
  local file="$1"
  [[ -f "$file" ]] || cw_die "APT package file not found: $file"
  mapfile -t packages < <(cw_read_package_file "$file")
  ((${#packages[@]} > 0)) || {
    cw_log "No apt packages in $file"
    return 0
  }
  cw_run sudo apt-get update
  cw_run sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
}

cw_install_binary_file() {
  local src="$1" dst="$2" mode="${3:-0755}"
  if [[ "$CW_DRY_RUN" == "true" ]]; then
    cw_run sudo install -m "$mode" "$src" "$dst"
    return 0
  fi
  [[ -f "$src" ]] || cw_die "Binary source not found: $src"
  cw_run sudo install -m "$mode" "$src" "$dst"
}

cw_download_file() {
  local url="$1" dst="$2"
  cw_run curl -fsSL --retry 5 --retry-delay 2 --retry-max-time 300 --retry-connrefused --retry-all-errors --connect-timeout 20 "$url" -o "$dst"
}

cw_verify_sha256() {
  local file="$1" expected="$2"
  [[ -n "$expected" ]] || {
    cw_err "Missing expected SHA256 for $file"
    return 1
  }
  if [[ "$CW_DRY_RUN" == "true" ]]; then
    cw_log "DRY-RUN: verify sha256 for $file"
    return 0
  fi
  local actual
  [[ -f "$file" ]] || {
    cw_err "File not found for SHA256 verification: $file"
    return 1
  }
  actual="$(sha256sum "$file" | awk '{print $1}')"
  if [[ "$actual" != "$expected" ]]; then
    cw_err "SHA256 mismatch for $file. expected=$expected actual=$actual"
    return 1
  fi
  cw_log "SHA256 verified: $file"
}

cw_arch_token() {
  case "$(uname -m)" in
  x86_64 | amd64) printf 'x86_64' ;;
  aarch64 | arm64) printf 'aarch64' ;;
  *) cw_die "Unsupported architecture: $(uname -m)" ;;
  esac
}

cw_sha256_from_manifest() {
  local manifest="$1" asset="$2" checksum
  [[ -f "$manifest" ]] || {
    cw_err "Checksum manifest not found: $manifest"
    return 1
  }
  checksum="$(awk -v asset="$asset" '$2 == asset || $2 == "./" asset || $NF == asset || $NF == "./" asset {print $1; exit}' "$manifest")"
  [[ -n "$checksum" ]] || {
    cw_err "Asset $asset not found in checksum manifest $manifest"
    return 1
  }
  printf '%s' "$checksum"
}

cw_verify_sha256_from_manifest() {
  local file="$1" manifest="$2" asset="$3" expected
  if [[ "$CW_DRY_RUN" == "true" ]]; then
    cw_log "DRY-RUN: verify sha256 for $file using manifest $manifest asset $asset"
    return 0
  fi
  expected="$(cw_sha256_from_manifest "$manifest" "$asset")" || return
  cw_verify_sha256 "$file" "$expected"
}

cw_canonicalize_path() {
  local path="$1"
  python3 - "$path" <<'PYCANON'
import pathlib, sys
print(pathlib.Path(sys.argv[1]).expanduser().resolve(strict=False))
PYCANON
}

cw_path_is_same_or_parent() {
  local maybe_parent="$1" child="$2"
  python3 - "$maybe_parent" "$child" <<'PYPATH'
import pathlib, sys
parent = pathlib.Path(sys.argv[1]).resolve(strict=False)
child = pathlib.Path(sys.argv[2]).resolve(strict=False)
if parent == child or parent in child.parents:
    raise SystemExit(0)
raise SystemExit(1)
PYPATH
}

cw_copy_with_backup() {
  local src="$1" dst="$2"
  [[ -f "$src" ]] || cw_die "Source file not found: $src"
  if [[ -f "$dst" ]]; then
    if ! cw_confirm_sensitive CARACODERS_CONFIRM_OVERWRITE_EXISTING "Overwrite existing file $dst? A backup will be created first."; then
      cw_warn "Skipping overwrite: $dst"
      return 0
    fi
    cw_backup_file "$dst"
  else
    cw_run mkdir -p "$(dirname "$dst")"
  fi
  cw_run install -m 0644 "$src" "$dst"
}

cw_copy_tree_with_backup() {
  local src_dir="$1" dst_dir="$2" rel src dst
  [[ -d "$src_dir" ]] || cw_die "Source directory not found: $src_dir"
  cw_run mkdir -p "$dst_dir"
  while IFS= read -r -d '' src; do
    rel="${src#"$src_dir"/}"
    dst="$dst_dir/$rel"
    if [[ -f "$dst" ]]; then
      cw_backup_file "$dst"
    else
      cw_run mkdir -p "$(dirname "$dst")"
    fi
    cw_run install -m 0644 "$src" "$dst"
  done < <(find "$src_dir" -type f -print0)
}
