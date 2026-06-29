# Install flow

1. Clone the repo and enter it:

```bash
git clone <repo-url> caracoders-workstation
cd caracoders-workstation
```

2. Review `README.md`, `docs/profiles.md`, `docs/decisions.md` and `docs/onboarding.md`.
3. Run a dry-run first from the repo root:

```bash
./bootstrap.sh --profile full --dry-run
```

4. Run the selected profile:

```bash
./bootstrap.sh --profile full
```

5. If Docker was installed or group membership changed, log out and back in before validating Docker-dependent checks.
6. Run validation:

```bash
./doctor.sh --profile full --strict
./verify.sh --profile full
```

The validation order is intentional: `doctor.sh` checks the actual workstation state, while `verify.sh` checks repository policy, templates, pins and script consistency.

## Silent mode

```bash
cp .caracoders-workstation.env.example .caracoders-workstation.env
nano .caracoders-workstation.env
./bootstrap.sh --profile full --yes --config ./.caracoders-workstation.env
```

The local config file is parsed as data. It supports simple `KEY=VALUE`, quoted values, `$HOME` and `${HOME}`. It does not support arbitrary Bash. Command substitution, backticks and semicolons are rejected.

The local config uses a strict key allowlist. Environment-control keys such as `PATH`, `IFS`, `BASH_ENV`, `SHELLOPTS`, internal `CW_*` keys and profile keys are rejected.

Sensitive actions require explicit consent variables in `--yes` mode. Example: Docker installation is skipped unless `CARACODERS_ALLOW_DOCKER_APT_REPO="true"` exists in the local ignored config.

`--dry-run --yes` mirrors that behavior: it reports sensitive actions as skipped unless the same consent variable is true. This prevents the dry-run from giving a more permissive picture than the real non-interactive execution.
