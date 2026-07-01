# caracoders-workstation

`caracoders-workstation` is the public Ubuntu workstation standard for Caracoders Pro Services C.A. It bootstraps development and support machines with an auditable, idempotent and conservative base. Reproducibility is controlled by Caracoders-approved versions in `config/versions.env` and package lists, not by unqualified `latest` installs.

Primary target: real Ubuntu 26.04 LTS. Secondary target: Ubuntu 24.04 LTS where package availability allows it. WSL is out of scope for v1.

## Strategy

The host stays clean and useful. Each project declares its own runtime.

- Ubuntu host: base CLI, Git, Docker Engine, VS Code, OpenCode, support/security tools.
- Project runtime: Docker Compose + Dev Containers.
- Laravel v1: PostgreSQL, Redis and Mailpit in containers.
- Database inspection: pgAdmin web container, `psql`, PostgreSQL MCP and container tools.
- AI workflow: OpenCode on host, MCPs scoped by policy, AGENTS global and AGENTS per project.

## What it installs

Base CLI, PHP CLI, Composer, Laravel Installer, Node via NVM, npm, pnpm, Docker Engine, Docker Compose plugin, VS Code, recommended VS Code extensions, OpenCode, MCP v1, Starship, support tools and security tooling depending on profile.

## What it does not install

Laravel Sail, DDEV, Portainer, UFW, OpenSSH server, SQLTools, PostgreSQL VS Code extension, shell MCP, tcpdump, tshark, Wireshark, global PostgreSQL/MySQL/Redis/Apache/Nginx/PHP-FPM servers, custom aliases, automatic backups or offensive tooling.

## Why Docker Compose and Dev Containers

Caracoders uses Docker Compose and Dev Containers because the environment becomes project-declared, reviewable and reproducible. The host installs the platform; the project owns runtime versions, services, ports and dependencies. Laravel-specific wrappers and all-in-one tools are intentionally not the standard because they hide Dockerfile, Compose services, healthchecks, volumes, non-root users and explicit runtime decisions.

## Install

Start with a clone of the released repository, then run the workstation flow from the repo root:

```bash
git clone <repo-url> caracoders-workstation
cd caracoders-workstation
./bootstrap.sh --profile full --dry-run
./bootstrap.sh --profile full
source "$HOME/.config/caracoders-workstation/bash/caracoders-workstation.sh"
# If Docker group membership changed: newgrp docker, or logout/login/reboot.
./doctor.sh --profile full --strict
./verify.sh --profile full
```

Use `full` for the standard Caracoders developer/support workstation. Use a smaller profile only when the machine has a narrower purpose and the operator understands the profile composition in `docs/profiles.md`.

### Post-install activation

After `./bootstrap.sh --profile full` finishes, activate the shell integration before judging same-terminal commands such as `node`, `npm`, `pnpm`, `opencode` or `laravel`:

```bash
source "$HOME/.config/caracoders-workstation/bash/caracoders-workstation.sh"
```

Opening a new terminal also loads the integration when the `.bashrc` block was approved. If Docker group membership changed or Docker is not accessible without `sudo`, run `newgrp docker`; otherwise log out and back in or reboot. If Docker still is not reachable, start the daemon with `sudo systemctl enable --now docker`.

Then validate in this order: `./doctor.sh --profile full --strict` validates the host workstation state, and `./verify.sh --profile full` validates this repository checkout, policies, pins and templates.

Read next:

- `docs/install-flow.md` for the exact install sequence.
- `docs/onboarding.md` for a technician/developer first-day checklist.
- `docs/release-policy.md` for branch, CI and version policy.
- `docs/pilot-plan.md` for validating a release on 1-2 machines before rollout.

Silent mode:

```bash
cp .caracoders-workstation.env.example .caracoders-workstation.env
./bootstrap.sh --profile full --yes --config ./.caracoders-workstation.env
```

Sensitive actions still require explicit config consent in `--yes` mode. The local config is parsed as simple `KEY=VALUE` data; it is not sourced as executable Bash.

## Profiles

`minimal`, `dev`, `laravel`, `docker`, `devcontainer`, `vscode`, `ai`, `support`, `security`, `full`.

`full` = `minimal + dev + laravel + docker + devcontainer + vscode + ai + support + security` plus Starship/dotfile integration. The real module composition lives in `config/profiles/full.env`.

## Required commands

```bash
./bootstrap.sh --help
./bootstrap.sh --profile minimal --dry-run
./bootstrap.sh --profile dev --dry-run
./bootstrap.sh --profile full --dry-run
./bootstrap.sh --profile full
./bootstrap.sh --profile full --yes --config ./.caracoders-workstation.env
./doctor.sh
./verify.sh
./update.sh --profile full
```

## Update

```bash
./update.sh --profile full --dry-run
./update.sh --profile full
```

## Rollback dotfiles

```bash
./scripts/rollback-dotfiles.sh --dry-run
./scripts/rollback-dotfiles.sh
```

## Laravel from template

```bash
mkdir my-app
cp -R templates/laravel/. my-app/
cd my-app
cp .env.example .env
cp Makefile.example Makefile
docker compose --env-file .env up -d --build
```

Then open the folder in VS Code and reopen in the Dev Container.


## Security corrections in v1.1-v1.6

- Local `.caracoders-workstation.env` is parsed as data, not sourced.
- `cw_run` does not use `eval`.
- Docker template ports bind to `127.0.0.1` by default.
- CI fails on Trivy HIGH/CRITICAL findings instead of reporting only.
- `config/profiles/*.env` and `packages/*` are the source of truth for profiles and packages.
- `php-dom` and `php-fileinfo` were removed from APT packages; `php-xml` covers DOM and the PHP CLI/common packages cover the expected fileinfo availability.

Additional v1.2-v1.6 hardening:

- `security/gitleaks.toml` is valid TOML and CI runs local Gitleaks with that config after installing checksum-verified security tools.
- The local config parser has a strict allowlist and rejects internal/dangerous keys such as `PATH`, `IFS`, `BASH_ENV`, `SHELLOPTS`, `CW_*` and profile variables.
- `ai` is self-contained as `minimal + dev + ai`, so NVM, git, Python and npm prerequisites are installed before OpenCode/MCP.
- OpenCode and MCP installers load NVM before requiring `npm`, avoiding failures in fresh non-login shells.
- `doctor.sh --strict` fails when required commands are missing for the selected profile.
- `verify.sh` validates TOML, JSON, profile drift, localhost port binds, package pinning, CI hardening and config parser blocking.
- CI includes Ubuntu 26.04 runner coverage in addition to Ubuntu 24.04.

## Estado v1.6

Esta versión cierra los P1 restantes detectados en la revisión de v1.5 sin declarar un rollback destructivo falso:

- MCP filesystem canonicaliza rutas con `realpath`/`Path.resolve(strict=False)` y rechaza `$HOME`, `$HOME/.`, `$HOME/..`, `/` y padres de HOME sin confirmación explícita.
- La prueba Docker usa `DOCKER_HELLO_WORLD_IMAGE` digest-pinned desde `config/versions.env`; `:latest` está prohibido.
- El perfil `security` instala Gitleaks, Trivy y Hadolint localmente en versiones controladas y verifica SHA256 antes de extraer/instalar.
- Starship y FiraCode Nerd Font se instalan desde releases versionados con verificación SHA256; no se usa instalador flotante.
- PECL Redis queda pinneado en el Dockerfile Laravel.
- Las imágenes Docker por defecto del template Laravel/pgAdmin y las etapas base del Dockerfile están digest-pinned.
- GitHub Actions usa `actions/checkout` pineado a SHA completo y ejecuta Gitleaks/Trivy/Hadolint como binarios locales checksum-verified, no como acciones externas por tag.
- La configuración global de OpenCode se copia con backups granulares por archivo existente.
- `verify.sh` valida el gate MCP canónico, `MCP_FILESYSTEM_ALLOWED_PATHS` explícitamente vacío, parser con `#` dentro de comillas, smoke image digest, digest pinning de templates, checksums de herramientas/font y YAML cuando hay parser disponible.

- `install-mcp.sh` valida y canonicaliza `MCP_FILESYSTEM_ALLOWED_PATHS` antes de cualquier `npm install` o escritura de configuración, por lo que una política MCP inválida falla sin modificar estado.
- `install-docker.sh` descarga la clave APT de Docker a un archivo temporal sin sudo, verifica el fingerprint aprobado en `config/versions.env` y solo entonces la instala en `/etc/apt/keyrings/docker.asc`.
- El perfil `security` reinstala las versiones aprobadas de Gitleaks/Trivy/Hadolint después de verificar SHA256, incluso si ya existe un binario previo en la máquina.

Rollback completo de paquetes/repos/configs sigue siendo deliberadamente conservador: `rollback-dotfiles.sh` revierte el bloque marcado de Bash; `rollback-manifest.sh` ayuda a auditar lo instalado sin ejecutar borrados destructivos.
