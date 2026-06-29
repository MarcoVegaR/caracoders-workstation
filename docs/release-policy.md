# Release policy

Caracoders workstation releases move through explicit review, CI and pilot stages before broad installation.

## Version Meaning

- `v1.5.0-rc1`: internal release candidate for controlled testing.
- `v1.5.0`: stable release after internal validation and pilot approval.
- `v1.5.1`: bugfix release for compatible fixes that do not add broad new capabilities.
- `v1.6.0`: minor release for new capabilities, hardening or policy improvements that remain compatible with the workstation standard.

## Main Branch Rules

- Nothing enters `main` without CI passing.
- Scripts that install packages, modify system configuration, write dotfiles, configure Docker, configure MCP or touch security tooling require pull request review.
- Sensitive scripts require extra scrutiny for ordering, integrity checks, consent variables and rollback/audit behavior.
- Release candidates must pass repository verification and at least one real-machine pilot before being promoted to stable.

## Release Gate

Before publishing a release candidate or stable release:

```bash
./bootstrap.sh --profile full --dry-run
./doctor.sh --profile full --strict
./verify.sh --profile full
bash -n bootstrap.sh doctor.sh verify.sh update.sh scripts/*.sh scripts/lib/*.sh
```

Record known limitations in the release notes instead of hiding them. Examples include integrity coverage gaps, grep-based verification checks or external provider key verification limitations.
