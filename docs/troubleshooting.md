# Troubleshooting

## Docker permission denied

After Docker group changes, run `newgrp docker`; otherwise log out and back in or reboot. If the session already has the `docker` group but Docker is still unreachable, start the daemon with `sudo systemctl enable --now docker` and retry `docker info`.

The Docker group is intentionally gated because membership effectively grants high local privileges.

## NVM/npm not found in a script

After bootstrap, same-terminal commands may not see the shell integration yet. Open a new terminal or run:

```bash
source "$HOME/.config/caracoders-workstation/bash/caracoders-workstation.sh"
```

If Node is still unavailable, run:

```bash
./scripts/install-node-nvm.sh --profile dev
./doctor.sh --profile ai --strict
```

OpenCode and MCP installers call the shared NVM loader before requiring `npm`, but an interrupted Node installation can still leave the shell without a usable default Node.

## Ports busy

Change forwarded ports in the project `.env`. Template ports bind to `127.0.0.1` by default.

## Gitleaks config fails

Run:

```bash
python3 -c "import tomllib; tomllib.load(open('security/gitleaks.toml','rb'))"
```

Do not use unescaped backslashes inside double-quoted TOML strings. Prefer TOML literal strings for regexes.

## Strict doctor fails

`doctor.sh --strict` fails if a command required by the selected profile is missing or if a warning remains. Activate shell integration, refresh Docker group membership if needed, re-run the relevant profile installer only if something is still missing, then re-run doctor. For example:

```bash
./bootstrap.sh --profile laravel --yes
./doctor.sh --profile laravel --strict
```
