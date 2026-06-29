# Secrets policy

Real secrets never live in this repo. `.caracoders-workstation.env` is ignored and exists only on the local machine.

## Parser behavior

The bootstrap does not `source` the local config. It parses simple `KEY=VALUE` data and rejects command substitution, backticks and semicolons. It also applies a strict key allowlist.

Allowed local config categories:

- `CARACODERS_USER_NAME`, `CARACODERS_USER_EMAIL`
- `GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `GITHUB_USERNAME`
- `OPENCODE_PROVIDER`, `OPENCODE_API_KEY`
- `MCP_FILESYSTEM_ALLOW_HOME`, `MCP_FILESYSTEM_ALLOWED_PATHS`
- `INSTALL_VSCODE_EXTENSIONS`, `INSTALL_STARSHIP_FONT`
- explicit consent gates: `CARACODERS_CONFIRM_*`, `CARACODERS_ALLOW_*`

Blocked examples:

- `PATH`
- `IFS`
- `BASH_ENV`
- `SHELLOPTS`
- `CW_*`
- `PROFILE_*`
- `LD_*`
- `SUDO_*`

## OpenCode and MCP

OpenCode API keys must be configured outside the repo. MCP PostgreSQL uses development credentials only. Do not store production database URLs, browser sessions or provider tokens in committed files.

## CI

CI installs the approved checksum-verified Gitleaks binary through `install-security-tools.sh` and then runs `gitleaks detect --config security/gitleaks.toml` as a blocking check.
