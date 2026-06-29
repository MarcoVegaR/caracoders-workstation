# Troubleshooting

## Docker permission denied

Logout/login after Docker group changes. The Docker group is intentionally gated because membership effectively grants high local privileges.

## NVM/npm not found in a script

Run:

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

`doctor.sh --strict` fails if a command required by the selected profile is missing. Re-run the relevant profile installer, then re-run doctor. For example:

```bash
./bootstrap.sh --profile laravel --yes
./doctor.sh --profile laravel --strict
```
