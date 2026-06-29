# Update policy

The repo owns Caracoders-approved versions and package lists. Do not change workstation versions ad hoc on each machine.

Primary files:

- `config/versions.env`: approved runtime/tool versions and package constraints.
- `config/profiles/*.env`: profile module composition.
- `packages/apt-*.txt`: APT package source of truth.
- `packages/npm-global.txt`: global npm package source of truth.
- `packages/composer-global.txt`: global Composer package source of truth.

Update flow:

```bash
git pull --ff-only
./update.sh --profile full --dry-run
./update.sh --profile full
./doctor.sh --profile full --strict
```

## Reproducibility level

v1.6 pins or constrains workstation-level tools enough to avoid random `latest` drift for Node, Composer, pnpm, OpenCode, MCP packages and security tool releases. Default Docker images in the Laravel/pgAdmin templates are digest-pinned, including the Dockerfile base stages. Updating those digests is now an explicit repository maintenance task, not something each workstation resolves independently.

## Rollback policy v1.6

`rollback-dotfiles.sh` is the only automatic rollback path because it edits a marked, reversible `.bashrc` block and creates backups.

`rollback-manifest.sh` is audit-first: it shows the installation manifest and a manual rollback checklist. It intentionally does not remove APT repositories, packages, group memberships, global npm/composer packages, fonts, VS Code config, OpenCode config, or MCP config automatically. Removing those automatically can break user-owned state. A future v2 rollback must track action classes and ownership before attempting destructive reversals.

