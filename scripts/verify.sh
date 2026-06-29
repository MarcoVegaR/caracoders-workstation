#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
cw_parse_args "$@"
cw_load_config
cw_check_profile
cd "$CW_ROOT"

cw_log "Verifying repository structure"
required=(
  README.md SECURITY.md CONTRIBUTING.md LICENSE .gitignore .editorconfig .yamllint.yml .hadolint.yaml .caracoders-workstation.env.example
  config/versions.env scripts/bootstrap.sh scripts/preflight.sh scripts/doctor.sh scripts/verify.sh scripts/update.sh
  scripts/rollback-dotfiles.sh scripts/install-apt.sh scripts/install-docker.sh templates/laravel/docker-compose.yml
  templates/laravel/.devcontainer/devcontainer.json config/opencode/AGENTS.md config/opencode/mcp/README.md
  security/gitleaks.toml .github/workflows/lint.yml .github/workflows/security.yml .github/workflows/install-test.yml
)
for f in "${required[@]}"; do
  [[ -e "$CW_ROOT/$f" ]] || cw_die "Missing required file: $f"
done

cw_log "Checking Bash syntax"
while IFS= read -r -d '' file; do
  bash -n "$file"
done < <(find "$CW_ROOT/scripts" -name '*.sh' -print0)
for wrapper in bootstrap.sh doctor.sh verify.sh update.sh; do
  bash -n "$CW_ROOT/$wrapper"
done

cw_log "Checking unsafe shell patterns"
forbidden_word="e""val"
grep -R --line-number -E "\b${forbidden_word}\b" "$CW_ROOT/scripts" >/tmp/caracoders-verify-dyn-run.txt 2>/dev/null || true
if [[ -s /tmp/caracoders-verify-dyn-run.txt ]]; then
  cat /tmp/caracoders-verify-dyn-run.txt >&2
  cw_die "Forbidden dynamic shell execution found in scripts."
fi
if grep -R --line-number -E 'source \$CW_CONFIG|source "\$CW_CONFIG"|\. \$CW_CONFIG|\. "\$CW_CONFIG"' "$CW_ROOT/scripts" >/tmp/caracoders-verify-source-config.txt 2>/dev/null; then
  cat /tmp/caracoders-verify-source-config.txt >&2
  cw_die "Local config must be parsed as data, not sourced."
fi

cw_log "Checking safe config parser allowlist"
for blocked_key in PATH IFS BASH_ENV SHELLOPTS CW_ROOT CW_DRY_RUN PROFILE_MODULES; do
  tmp="$(mktemp)"
  printf '%s="bad"
' "$blocked_key" >"$tmp"
  if bash -c 'source scripts/lib/common.sh; cw_load_key_value_file "$1" local-config' _ "$tmp" >/tmp/caracoders-parser-test.out 2>/tmp/caracoders-parser-test.err; then
    cat /tmp/caracoders-parser-test.out /tmp/caracoders-parser-test.err >&2 || true
    rm -f "$tmp"
    cw_die "Config parser accepted forbidden key: $blocked_key"
  fi
  rm -f "$tmp"
done

tmp="$(mktemp)"
printf 'CARACODERS_USER_NAME="Marco # Caracoders" # allowed comment
' >"$tmp"
if ! bash -c 'source scripts/lib/common.sh; cw_load_key_value_file "$1" local-config; [[ "$CARACODERS_USER_NAME" == "Marco # Caracoders" ]]' _ "$tmp" >/tmp/caracoders-parser-hash.out 2>/tmp/caracoders-parser-hash.err; then
  cat /tmp/caracoders-parser-hash.out /tmp/caracoders-parser-hash.err >&2 || true
  rm -f "$tmp"
  cw_die "Config parser mishandled # inside quoted values."
fi
rm -f "$tmp"

cw_log "Checking MCP canonical path gates and side-effect ordering"
python3 - <<'PYMCPSTATIC'
import pathlib
import sys
text = pathlib.Path('scripts/install-mcp.sh').read_text(encoding='utf-8').splitlines()

def first_exact(exact):
    for i, line in enumerate(text, start=1):
        if line.strip() == exact:
            return i
    raise SystemExit(f'missing expected exact line: {exact}')

def first_contains(needle):
    for i, line in enumerate(text, start=1):
        if needle in line and not line.strip().startswith('#'):
            return i
    raise SystemExit(f'missing expected marker: {needle}')

validate_call = first_exact('validate_mcp_filesystem_paths')
require = first_exact('cw_require_npm')
install = first_contains('npm install -g')
if not (validate_call < require < install):
    raise SystemExit(f'MCP validation order is unsafe: validate_call={validate_call}, require={require}, npm_install={install}')
required_markers = [
    'MCP_FILESYSTEM_ALLOWED_PATHS was explicitly set empty',
    'cw_canonicalize_path "$path"',
    'cw_path_is_same_or_parent "$canon" "$home_canon"',
    'cw_confirm_sensitive CARACODERS_CONFIRM_MCP_HOME_ACCESS',
    'cw_confirm_sensitive CARACODERS_CONFIRM_MCP_OUTSIDE_HOME_ACCESS',
]
joined = '\n'.join(text)
for marker in required_markers:
    if marker not in joined:
        raise SystemExit(f'MCP installer missing policy marker: {marker}')

home = pathlib.Path.home().resolve(strict=False)
root = pathlib.Path('/').resolve(strict=False)
bad = [home, home / '.', home / '..', root, pathlib.Path('/home')]
for path in bad:
    canon = path.resolve(strict=False)
    is_root = canon == root
    is_home = canon == home
    is_parent_of_home = canon in home.parents
    if not (is_root or is_home or is_parent_of_home):
        raise SystemExit(f'MCP static canonical policy test failed for {path} -> {canon}')
PYMCPSTATIC

cw_log "Checking TOML/JSON parseability"
python3 - <<'PYVERIFY'
import json
import pathlib
import tomllib
root = pathlib.Path('.')
for path in [root / 'security/gitleaks.toml']:
    with path.open('rb') as handle:
        tomllib.load(handle)
for path in [root / 'config/vscode/settings.json', root / 'config/vscode/keybindings.example.json']:
    with path.open('r', encoding='utf-8') as handle:
        json.load(handle)
for path in (root / 'config/opencode/mcp').glob('*.json'):
    with path.open('r', encoding='utf-8') as handle:
        json.load(handle)
PYVERIFY

cw_log "Checking YAML parseability when parser is available"
if python3 - <<'PYYAML' >/dev/null 2>&1; then
import yaml
PYYAML
  python3 - <<'PYYAML'
import pathlib
import yaml
for path in list(pathlib.Path('.github/workflows').glob('*.yml')) + list(pathlib.Path('templates').glob('**/*.yml')) + [pathlib.Path('.yamllint.yml'), pathlib.Path('.hadolint.yaml')]:
    with path.open('r', encoding='utf-8') as handle:
        yaml.safe_load(handle)
PYYAML
elif command -v yamllint >/dev/null 2>&1; then
  yamllint .github/workflows templates .yamllint.yml .hadolint.yaml
else
  cw_warn "No YAML parser available locally. CI lint workflow installs yamllint and validates YAML."
fi

cw_log "Checking profile definitions"
known_modules=' minimal dev laravel docker devcontainer vscode ai support security starship dotfiles '
for profile_file in "$CW_ROOT"/config/profiles/*.env; do
  profile_name="$(basename "$profile_file" .env)"
  while IFS= read -r module; do
    [[ "$known_modules" == *" $module "* ]] || cw_die "Unknown module '$module' in $profile_file"
  done < <(CW_PROFILE="$profile_name" cw_profile_modules "$profile_name")
done
if ! grep -q 'PROFILE_MODULES="minimal dev ai"' "$CW_ROOT/config/profiles/ai.env"; then
  cw_die "AI profile must be self-contained: expected minimal dev ai modules."
fi

cw_log "Checking forbidden active assets"
if grep -R "@modelcontextprotocol/server-shell\|mcp-shell" "$CW_ROOT/packages" "$CW_ROOT/config/opencode/mcp" >/dev/null 2>&1; then
  cw_die "Forbidden shell MCP package reference found in active package/config assets."
fi
if grep -R "mtxr.sqltools\|PostgreSQL.vscode-postgresql" "$CW_ROOT/config/vscode/extensions.recommended.txt" >/dev/null 2>&1; then
  cw_die "Rejected SQL VS Code extension found in recommended list."
fi
[[ ! -f "$CW_ROOT/.caracoders-workstation.env" ]] || cw_die ".caracoders-workstation.env must not exist in repository tree for packaging/CI."

cw_log "Checking Docker Compose localhost binds and digest-pinned images"
python3 - <<'PYPORTS'
import pathlib
import re
import sys
files = [pathlib.Path('templates/laravel/docker-compose.yml'), pathlib.Path('templates/pgadmin/docker-compose.yml')]
errors = []
for path in files:
    for lineno, line in enumerate(path.read_text(encoding='utf-8').splitlines(), start=1):
        stripped = line.strip()
        if re.match(r'''^-\s*["']?(?:\$\{[A-Z0-9_]+|[0-9]+:)''', stripped):
            errors.append(f'{path}:{lineno}: published port must bind to 127.0.0.1: {stripped}')
        if stripped.startswith('image:'):
            image = stripped.split(':', 1)[1].strip().strip('"\'')
            if ':-' in image:
                default = image.split(':-', 1)[1].rstrip('}')
            else:
                default = image
            if '@sha256:' not in default:
                errors.append(f'{path}:{lineno}: image default must be digest-pinned: {stripped}')
            if ':latest' in default:
                errors.append(f'{path}:{lineno}: image must not use latest tag: {stripped}')

# Also enforce digest-pinned Dockerfile stage images declared through ARG defaults.
dockerfile = pathlib.Path('templates/laravel/Dockerfile')
for lineno, line in enumerate(dockerfile.read_text(encoding='utf-8').splitlines(), start=1):
    stripped = line.strip()
    if stripped.startswith('ARG ') and '_IMAGE=' in stripped:
        default = stripped.split('=', 1)[1].strip()
        if '@sha256:' not in default:
            errors.append(f'{dockerfile}:{lineno}: Dockerfile image ARG must be digest-pinned: {stripped}')
        if ':latest' in default:
            errors.append(f'{dockerfile}:{lineno}: Dockerfile image ARG must not use latest: {stripped}')
if errors:
    print('\n'.join(errors), file=sys.stderr)
    raise SystemExit(1)
PYPORTS

cw_log "Checking controlled versions, Docker smoke image, and package pinning"
if grep -R --line-number -E 'latest-stable|latest-supported|NODE_VERSION="lts"|:latest' "$CW_ROOT/config" "$CW_ROOT/packages" "$CW_ROOT/templates" "$CW_ROOT/.github" >/tmp/caracoders-verify-moving.txt 2>/dev/null; then
  cat /tmp/caracoders-verify-moving.txt >&2
  cw_die "Moving version alias or latest tag found in active assets."
fi

[[ "$(tr -d '[:space:]' <"$CW_ROOT/packages/node-version")" == "${NODE_VERSION:-}" ]] || cw_die "packages/node-version must match NODE_VERSION in config/versions.env."

DOCKER_HELLO_WORLD_IMAGE_CHECK="${DOCKER_HELLO_WORLD_IMAGE:-}"
[[ -n "$DOCKER_HELLO_WORLD_IMAGE_CHECK" ]] || cw_die "DOCKER_HELLO_WORLD_IMAGE must be set in config/versions.env"
[[ "$DOCKER_HELLO_WORLD_IMAGE_CHECK" != *':latest'* ]] || cw_die "DOCKER_HELLO_WORLD_IMAGE must not use :latest"
[[ "$DOCKER_HELLO_WORLD_IMAGE_CHECK" == *@sha256:* ]] || cw_die "DOCKER_HELLO_WORLD_IMAGE must be digest-pinned"
grep -q 'docker run --rm "$smoke_image"' "$CW_ROOT/scripts/install-docker.sh" || cw_die "install-docker.sh must use the digest-pinned DOCKER_HELLO_WORLD_IMAGE smoke image."

[[ -n "${DOCKER_APT_KEY_FINGERPRINT:-}" ]] || cw_die "DOCKER_APT_KEY_FINGERPRINT must be set in config/versions.env"
[[ "${DOCKER_APT_KEY_FINGERPRINT}" =~ ^[0-9A-Fa-f]{40}$ ]] || cw_die "DOCKER_APT_KEY_FINGERPRINT must be a full 40-hex fingerprint."
grep -q 'gpg --show-keys --with-colons' "$CW_ROOT/scripts/install-docker.sh" || cw_die "install-docker.sh must inspect the downloaded Docker APT key fingerprint before installing it."
grep -q 'actual_fingerprint.*docker_key_fingerprint' "$CW_ROOT/scripts/install-docker.sh" || cw_die "install-docker.sh must compare the downloaded Docker APT key fingerprint to config/versions.env."
if grep -q 'sudo curl .*download.docker.com/linux/ubuntu/gpg' "$CW_ROOT/scripts/install-docker.sh"; then
  cw_die "install-docker.sh must not download the Docker APT key directly with sudo curl."
fi

for pkg in opencode-ai @modelcontextprotocol/server-filesystem @playwright/mcp @upstash/context7-mcp @modelcontextprotocol/server-postgres pnpm; do
  grep -Eq "^${pkg//\//\/}@[^[:space:]]+" "$CW_ROOT/packages/npm-global.txt" || cw_die "Missing pinned npm package: $pkg"
done

cw_log "Checking security/starship/PECL pinning"
grep -q 'install_gitleaks' "$CW_ROOT/scripts/install-security-tools.sh" || cw_die "security profile must install gitleaks locally, not only warn."
grep -q 'install_trivy' "$CW_ROOT/scripts/install-security-tools.sh" || cw_die "security profile must install trivy locally, not only warn."
grep -q 'install_hadolint' "$CW_ROOT/scripts/install-security-tools.sh" || cw_die "security profile must install hadolint locally, not only warn."
grep -q 'cw_verify_sha256_from_manifest "$archive" "$checksums" "$asset"' "$CW_ROOT/scripts/install-security-tools.sh" || cw_die "security binary archives must be SHA256-verified from release checksum manifests before extraction."
grep -q 'cw_verify_sha256 "$bin" "$expected"' "$CW_ROOT/scripts/install-security-tools.sh" || cw_die "direct security binaries must be SHA256-verified before install."
if grep -Eq 'if cw_command_exists (gitleaks|trivy|hadolint); then[[:space:]]*$' "$CW_ROOT/scripts/install-security-tools.sh" && grep -q 'return 0' "$CW_ROOT/scripts/install-security-tools.sh"; then
  cw_die "security installers must not early-return solely because a binary already exists; they must install the approved checksum-verified version."
fi
if grep -q 'starship.rs/install.sh' "$CW_ROOT/scripts/install-starship.sh"; then
  cw_die "Starship installer must not use the floating official install script in v1.6."
fi
grep -q 'STARSHIP_X86_64_GNU_SHA256' "$CW_ROOT/scripts/install-starship.sh" || cw_die "Starship install must verify an approved checksum."
grep -q 'NERD_FONT_CHECKSUMS_URL' "$CW_ROOT/config/versions.env" || cw_die "Nerd Font checksum manifest URL must be controlled by config/versions.env."
grep -q 'cw_verify_sha256_from_manifest "$font_zip" "$checksums" "${font_name}.zip"' "$CW_ROOT/scripts/install-starship.sh" || cw_die "Nerd Font archive must be SHA256-verified before unzip/install."
grep -q 'pecl install redis-${PECL_REDIS_VERSION}' "$CW_ROOT/templates/laravel/Dockerfile" || cw_die "Dockerfile must pin PECL redis through PECL_REDIS_VERSION."

cw_log "Checking AI npm bootstrap integration"
grep -q 'cw_require_npm' "$CW_ROOT/scripts/install-opencode.sh" || cw_die "install-opencode.sh must load/require npm through cw_require_npm."
grep -q 'cw_require_npm' "$CW_ROOT/scripts/install-mcp.sh" || cw_die "install-mcp.sh must load/require npm through cw_require_npm."
grep -q 'cw_copy_tree_with_backup "$CW_ROOT/config/opencode" "$HOME/.config/opencode"' "$CW_ROOT/scripts/install-opencode.sh" || cw_die "install-opencode.sh must copy global config with granular backups."

cw_log "Checking CI hardening"
python3 - <<'PYACTIONS'
import pathlib
import re
import sys
errors = []
for path in pathlib.Path('.github/workflows').glob('*.yml'):
    for lineno, line in enumerate(path.read_text(encoding='utf-8').splitlines(), start=1):
        match = re.search(r'uses:\s*([^\s#]+)', line)
        if not match:
            continue
        ref = match.group(1)
        if '@' not in ref:
            errors.append(f'{path}:{lineno}: action ref missing @sha: {ref}')
            continue
        sha = ref.rsplit('@', 1)[1]
        if not re.fullmatch(r'[0-9a-f]{40}', sha):
            errors.append(f'{path}:{lineno}: GitHub Action must be pinned to full commit SHA, not tag/branch: {ref}')
if errors:
    print('\n'.join(errors), file=sys.stderr)
    raise SystemExit(1)
PYACTIONS
grep -q 'ubuntu-26.04' "$CW_ROOT/.github/workflows/install-test.yml" || cw_die "install-test workflow must validate Ubuntu 26.04."
grep -q './scripts/install-security-tools.sh --profile security --yes' "$CW_ROOT/.github/workflows/security.yml" || cw_die "security workflow must install checksum-verified local security tools."
grep -q 'gitleaks detect --config security/gitleaks.toml' "$CW_ROOT/.github/workflows/security.yml" || cw_die "security workflow must run local gitleaks with repository config."
grep -q 'trivy fs --severity CRITICAL,HIGH --ignore-unfixed --exit-code 1 .' "$CW_ROOT/.github/workflows/security.yml" || cw_die "security workflow must run local trivy with blocking exit code."
grep -q 'hadolint --config .hadolint.yaml templates/laravel/Dockerfile' "$CW_ROOT/.github/workflows/security.yml" || cw_die "security workflow must run local hadolint."
if grep -R --line-number '|| true' "$CW_ROOT/.github/workflows" >/tmp/caracoders-verify-ci-true.txt 2>/dev/null; then
  cat /tmp/caracoders-verify-ci-true.txt >&2
  cw_die "CI must not hide failures with '|| true'."
fi

cw_log "Verify completed successfully"
