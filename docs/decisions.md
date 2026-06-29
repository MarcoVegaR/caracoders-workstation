# Technical decisions

## Shared Bash library

`scripts/lib/common.sh` was added to avoid duplicating argument parsing, logging, dry-run handling, config loading, backups and sensitive confirmations. The requested scripts remain present.

## Host stays clean

No global PostgreSQL, MySQL, Redis, Nginx, Apache or PHP-FPM server is installed. Runtime daemons live in containers.

## Docker Engine

Docker Engine and Compose plugin are enough for Linux workstations. Docker Desktop and Portainer are outside v1.

## Dev Containers

Dev Containers are mandatory because each project must declare its runtime.

## AnyDesk

AnyDesk has a confirmation gate but no installer in v1 until source, risk and removal policy are approved.

## Laravel Nginx config

The Laravel template adds `templates/laravel/docker/nginx/default.conf` because the Compose file references Nginx. This is a technical addition beyond the minimum tree so the template can actually boot.

## Safe config parser instead of `source`

Local `.caracoders-workstation.env` is treated as data, not executable Bash. `scripts/lib/common.sh` parses simple `KEY=VALUE` assignments, rejects command substitution, rejects backticks and rejects semicolons. This avoids executing arbitrary user-local config during a sudo-capable bootstrap. The tradeoff is intentional: the config file no longer supports arbitrary Bash syntax. Use literals, quoted strings and `$HOME`/`${HOME}` only.

## No `eval` in command execution

`cw_run` executes commands with Bash arrays (`"$@"`) and logs a shell-quoted representation for audit. It does not run strings through `eval`. Commands that previously required pipes or redirects now use purpose-built helpers such as `cw_sudo_write_file` or explicit script logic.

## Profiles and packages as source of truth

`config/profiles/*.env` declares `PROFILE_MODULES`. `bootstrap.sh` reads those modules and executes module installers. `install-apt.sh` reads the same module list and maps modules to `packages/apt-*.txt`. This avoids the previous drift risk where the profile files documented one thing while the script hardcoded another.

## Localhost-only template ports

Laravel and pgAdmin templates bind published ports to `127.0.0.1` by default. This reduces accidental exposure on shared networks. Teams that need LAN access must change the bind explicitly in a project fork and document the reason.

## Version policy v1.1-v1.6

The repo now avoids unqualified `latest` for approved workstation-level versions. Node, Composer, pnpm, OpenCode and MCP packages are pinned or constrained in `config/versions.env` and package lists. Default Docker images in templates and Dockerfile base stages are digest-pinned. Updating digests is a deliberate repo maintenance task, not an implicit workstation-side update.

## Strict local config allowlist

The local config parser does not export arbitrary keys. It allows only approved Caracoders user metadata, Git identity, OpenCode placeholders, MCP filesystem policy, installation toggles and explicit `CARACODERS_CONFIRM_*` / `CARACODERS_ALLOW_*` consent gates. It blocks environment-control and internal keys such as `PATH`, `IFS`, `BASH_ENV`, `SHELLOPTS`, `CW_*`, `PROFILE_*`, `LD_*` and `SUDO_*`. This is intentionally stricter than a normal `.env` parser because the bootstrap can run sudo operations.

## Self-contained AI profile

`ai` now expands to `minimal dev ai`. OpenCode/MCP installation depends on git, Python and Node/NPM through NVM. Treating `ai` as only `ai` made clean machines fragile. The profile is slightly larger, but it is operationally safer and predictable.

## Dry-run sensitive actions

`--dry-run --yes` models non-interactive execution more closely: sensitive actions are shown as skipped unless the relevant consent key is explicitly true in the supplied config. Earlier behavior could imply that dry-run would take paths that real `--yes` would not take.

## CI scope v1.2-v1.6

CI validates Ubuntu 24.04 and 26.04 for dry-run, minimal, dev and APT candidate checks. Laravel, AI and security smoke installs run on Ubuntu 24.04/26.04 where feasible to catch real host-toolchain errors without turning CI into a full workstation installer. Full GUI/Docker/VScode/Starship execution remains out of CI because it requires sensitive confirmations and interactive workstation state.

## Rollback scope

`rollback-dotfiles.sh` reverses the marked `.bashrc` block only. Broader rollback is tracked as a future enhancement. `cw_run` writes a lightweight install manifest to `${XDG_STATE_HOME:-$HOME/.local/state}/caracoders-workstation/install-manifest.log` so a later version can implement safer package/config rollback without guessing.

## Starship activation is manual

Starship can be installed and configured, but the shared `.bashrc` block does not auto-run the generated Starship shell initialization. This avoids adding generated shell execution to every terminal session. Users who want the Starship prompt can enable it manually after reviewing the official init command.

## v1.3/v1.6 hardening decisions

- HOME-wide MCP filesystem access is denied unless explicitly confirmed, even when supplied indirectly through `MCP_FILESYSTEM_ALLOWED_PATHS`.
- Docker smoke validation uses a digest-pinned `DOCKER_HELLO_WORLD_IMAGE` instead of `hello-world`/`hello-world:latest`.
- The `security` profile installs Gitleaks, Trivy and Hadolint as version-controlled local binaries instead of only documenting CI usage.
- Starship installation no longer uses the floating official install script; the x86_64 release archive is versioned and checksum-verified.
- PECL Redis is pinned in the Laravel Dockerfile through `PECL_REDIS_VERSION`.
- Rollback remains conservative: automatic rollback is limited to marked dotfile blocks; broader rollback is audit-first through the manifest.

- `install-mcp.sh` validates MCP filesystem scope before installing npm packages or writing config. Invalid MCP policy must fail before side effects.
- Docker APT key installation follows the official keyring/signed-by approach but adds a repo-controlled fingerprint check before installing the downloaded key.
- Security tools are not trusted merely because a binary already exists on the machine; the profile installs the approved checksum-verified version into `/usr/local/bin`.

