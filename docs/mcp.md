# MCP

| MCP | Status | Use |
|---|---|---|
| filesystem | installed | Scoped workspace file access |
| playwright | installed | Local UI/browser testing |
| context7 | installed | Documentation lookup |
| postgres | installed | Development database inspection |
| shell | rejected | Too broad for v1 |

The approved npm package versions live in `config/versions.env` and `packages/npm-global.txt`.

Filesystem defaults to `$HOME/projects,$HOME/caracoders`. All-HOME access requires both `MCP_FILESYSTEM_ALLOW_HOME="true"` and explicit confirmation. In `--yes` mode, the bootstrap will not enable whole-HOME access unless the matching consent gate is present.

PostgreSQL MCP is for development databases only. Do not point it at production credentials.

## HOME-wide filesystem access policy v1.6

`MCP_FILESYSTEM_ALLOWED_PATHS` is canonicalized before policy checks. `$HOME`, `$HOME/.`, `$HOME/..`, `/` and parents of HOME are treated as broad access even when `MCP_FILESYSTEM_ALLOW_HOME=false`. The installer aborts unless HOME access is explicitly approved through the sensitive confirmation gate. In `--yes` mode, this requires `CARACODERS_CONFIRM_MCP_HOME_ACCESS=true`. The default remains scoped project directories only. If `MCP_FILESYSTEM_ALLOWED_PATHS` is explicitly set to an empty string, the installer fails instead of silently falling back to defaults.


## Canonical path validation

v1.6 validates filesystem MCP paths before any npm install or config write, after canonicalization. This prevents bypasses such as `$HOME/.`, `$HOME/..`, `/`, symlink-normalized equivalents and parent directories that would effectively grant wider access than the operator intended. Outside-HOME paths require the separate `CARACODERS_CONFIRM_MCP_OUTSIDE_HOME_ACCESS=true` gate in `--yes` mode.

## Side-effect ordering

Filesystem MCP path validation intentionally happens before `cw_require_npm`, `npm install -g` or writes under `~/.config/opencode`. A bad `MCP_FILESYSTEM_ALLOWED_PATHS` value must abort without changing machine state.
