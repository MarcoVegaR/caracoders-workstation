#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
cw_parse_args "$@"
cw_load_config
cw_check_profile

validate_mcp_filesystem_paths() {
  local allowed_paths raw_path path canon home_canon root_canon
  validated_paths=()
  home_requested="false"
  outside_home_requested="false"

  if [[ -v MCP_FILESYSTEM_ALLOWED_PATHS ]]; then
    [[ -n "$(cw_trim "$MCP_FILESYSTEM_ALLOWED_PATHS")" ]] || cw_die "MCP_FILESYSTEM_ALLOWED_PATHS was explicitly set empty. Use scoped project directories or omit the variable to use safe defaults."
    allowed_paths="$MCP_FILESYSTEM_ALLOWED_PATHS"
  else
    allowed_paths="$HOME/projects,$HOME/caracoders"
  fi

  IFS=',' read -r -a raw_paths <<< "$allowed_paths"
  home_canon="$(cw_canonicalize_path "$HOME")"
  root_canon="/"

  for raw_path in "${raw_paths[@]}"; do
    path="$(cw_trim "$raw_path")"
    [[ -n "$path" ]] || continue
    path="${path//\$\{HOME\}/$HOME}"
    path="${path//\$HOME/$HOME}"
    [[ "$path" == ~/* ]] && path="$HOME/${path#~/}"
    canon="$(cw_canonicalize_path "$path")"

    if [[ "$canon" == "$root_canon" ]]; then
      home_requested="true"
      cw_warn "MCP filesystem path resolves to root (/): $raw_path"
      continue
    fi

    if [[ "$canon" == "$home_canon" ]]; then
      home_requested="true"
      cw_warn "MCP filesystem path resolves to HOME: $raw_path -> $canon"
      continue
    fi

    if cw_path_is_same_or_parent "$canon" "$home_canon"; then
      home_requested="true"
      cw_warn "MCP filesystem path resolves to HOME parent/broad scope: $raw_path -> $canon"
      continue
    fi

    if ! cw_path_is_same_or_parent "$home_canon" "$canon"; then
      outside_home_requested="true"
      cw_warn "MCP filesystem path is outside HOME and requires explicit approval: $raw_path -> $canon"
    fi

    validated_paths+=("$canon")
  done

  if [[ "${MCP_FILESYSTEM_ALLOW_HOME:-false}" == "true" ]]; then
    home_requested="true"
  fi

  if [[ "$home_requested" == "true" ]]; then
    if cw_confirm_sensitive CARACODERS_CONFIRM_MCP_HOME_ACCESS "Allow MCP filesystem access to entire HOME/root/HOME-parent scope?"; then
      validated_paths=("$home_canon")
    else
      cw_die "MCP filesystem broad access was requested but not explicitly approved. Use scoped project directories, not HOME, root, or HOME parents."
    fi
  fi

  if [[ "$outside_home_requested" == "true" ]]; then
    if ! cw_confirm_sensitive CARACODERS_CONFIRM_MCP_OUTSIDE_HOME_ACCESS "Allow MCP filesystem access outside HOME?"; then
      cw_die "MCP filesystem path outside HOME was requested without explicit approval. Keep paths under scoped project directories in HOME."
    fi
  fi

  if ((${#validated_paths[@]} == 0)); then
    cw_die "No MCP filesystem paths configured. Set MCP_FILESYSTEM_ALLOWED_PATHS to scoped project directories."
  fi
}

# Important: validate all filesystem MCP scope before any npm install or filesystem write.
validate_mcp_filesystem_paths

cw_require_npm

filesystem_pkg="$(cw_first_package_matching "$CW_ROOT/packages/npm-global.txt" '@modelcontextprotocol/server-filesystem@' || true)"
playwright_pkg="$(cw_first_package_matching "$CW_ROOT/packages/npm-global.txt" '@playwright/mcp@' || true)"
context7_pkg="$(cw_first_package_matching "$CW_ROOT/packages/npm-global.txt" '@upstash/context7-mcp@' || true)"
postgres_pkg="$(cw_first_package_matching "$CW_ROOT/packages/npm-global.txt" '@modelcontextprotocol/server-postgres@' || true)"
packages=(
  "${filesystem_pkg:-${MCP_FILESYSTEM_PACKAGE:-@modelcontextprotocol/server-filesystem@2026.1.14}}"
  "${playwright_pkg:-${MCP_PLAYWRIGHT_PACKAGE:-@playwright/mcp@0.0.76}}"
  "${context7_pkg:-${MCP_CONTEXT7_PACKAGE:-@upstash/context7-mcp@3.2.2}}"
  "${postgres_pkg:-${MCP_POSTGRES_PACKAGE:-@modelcontextprotocol/server-postgres@0.6.2}}"
)
package_names=(
  "@modelcontextprotocol/server-filesystem"
  "@playwright/mcp"
  "@upstash/context7-mcp"
  "@modelcontextprotocol/server-postgres"
)
for pkg in "${packages[@]}"; do
  cw_run npm install -g "$pkg"
done

cw_run mkdir -p "$HOME/.config/opencode/mcp/examples"
if [[ "$CW_DRY_RUN" == "false" ]]; then
  args_json=""
  for path in "${validated_paths[@]}"; do
    args_json+=", $(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$path")"
  done
  cat > "$HOME/.config/opencode/mcp/examples/filesystem.local.example.json" <<EOF_MCP
{
  "filesystem": {
    "command": "npx",
    "args": ["-y", "${packages[0]}"${args_json}],
    "note": "Review canonical paths before enabling. HOME/root/HOME-parent access requires explicit Caracoders confirmation."
  }
}
EOF_MCP
  cw_record_action "WRITE $HOME/.config/opencode/mcp/examples/filesystem.local.example.json"
else
  cw_log "DRY-RUN: write filesystem MCP example with canonical allowed paths: ${validated_paths[*]}"
fi

cw_run npm list -g --depth=0 "${package_names[@]}"
cw_log "MCP packages installed/verified. Shell MCP intentionally omitted."
