# Profiles

Profiles are declared in `config/profiles/*.env` through `PROFILE_MODULES`. The bootstrap reads those modules directly. Do not duplicate profile composition in code or docs without updating the config file.

| Profile | Modules | Purpose |
|---|---|---|
| minimal | `minimal` | Basic operating baseline: curl, wget, git, jq, tree, htop. |
| dev | `minimal dev dotfiles` | General development: GitHub CLI, ripgrep, fd, fzf, bat, eza, shellcheck, shfmt, pre-commit. |
| laravel | `minimal laravel dotfiles` | Laravel host productivity: PHP CLI, Composer, Laravel Installer, Node/NVM, psql. |
| docker | `minimal docker` | Docker Engine, Compose plugin and hello-world validation. |
| devcontainer | `minimal docker devcontainer` | Docker base plus project runtime standard through repository templates. |
| vscode | `minimal vscode` | VS Code and recommended extensions. |
| ai | `minimal dev ai` | OpenCode and MCP v1 with git, Python and NVM/npm prerequisites. |
| support | `minimal support` | Support diagnostics without pentest/offensive tooling. |
| security | `minimal dev security` | Repo protection tools and CI-backed scanners. |
| full | `minimal dev laravel docker devcontainer vscode ai support security starship dotfiles` | Standard Caracoders workstation. |

## APT package source of truth

APT packages live in `packages/apt-*.txt`. The installer maps profile modules to these package files. If a package is not in the relevant file, it is not part of that profile.

## Strict mode

`./doctor.sh --profile <profile> --strict` fails when required commands for the selected profile are missing. Use it after installation, in CI smoke tests and before declaring a machine ready.
