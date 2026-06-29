# Backup and rollback

Automatic workstation backup is not configured in v1. The scripts create timestamped backups before touching dotfiles.

Current rollback scope:

- `.bashrc` marked block through `scripts/rollback-dotfiles.sh`.
- Existing files copied through `cw_copy_with_backup` receive timestamped backups before overwrite.

Out of scope for v1.6:

- automatic APT package removal
- automatic removal of external APT repositories
- automatic Docker group reversal
- automatic VS Code/OpenCode/MCP config rollback
- automatic font removal

Every `cw_run` action writes a lightweight manifest to:

```bash
${XDG_STATE_HOME:-$HOME/.local/state}/caracoders-workstation/install-manifest.log
```

That manifest is audit data, not a full rollback engine yet.
