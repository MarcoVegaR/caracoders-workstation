# Contributing

This repository is the workstation standard for Caracoders. Contributions must be conservative, auditable and reversible.

## Rules

1. Prefer boring tools over fashionable tools.
2. Do not add global daemons unless the architecture document explicitly approves them.
3. Every installer must support `--dry-run`.
4. Every sensitive action must require confirmation or explicit config consent.
5. Do not commit secrets, real `.env` files or personal machine data.
6. Add documentation for any new profile, package group or external repository.
7. Keep scripts idempotent.

## Before opening a pull request

```bash
./verify.sh
./bootstrap.sh --profile full --dry-run
```
