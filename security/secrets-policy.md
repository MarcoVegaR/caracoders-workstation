# Secrets Policy

Secrets live in local ignored files, OS keyrings or provider dashboards. Never commit API keys, database passwords, SSH keys, browser sessions or production `.env` files.

## Local workstation config

`.caracoders-workstation.env` is ignored by Git and parsed as simple `KEY=VALUE` data. It is not sourced as Bash. Command substitution, backticks and semicolons are rejected by the bootstrap parser.

## Logging

Scripts must not print token values. Commands executed by `cw_run` are logged for audit, so never pass real tokens as command-line arguments. Prefer provider-native credential storage or local config files outside the repository.
