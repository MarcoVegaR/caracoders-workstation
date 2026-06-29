# Security assets

Security assets for the workstation repository. CI runs secret scanning, script linting, Dockerfile linting, Compose validation and filesystem vulnerability scanning before changes are merged. Security binaries are installed through this repo's checksum-verified installer before execution in CI.

Important files:

- `security/gitleaks.toml`: explicit Gitleaks config used by CI through `GITLEAKS_CONFIG`.
- `security/secrets-policy.md`: repository-level secret handling policy.
- `security/mcp-security.md`: MCP threat model and access policy.
- `security/docker-security.md`: Docker group and localhost port-binding guidance.

Local workstation security checks are useful, but CI is the enforcement point for this repo.

## Local security tooling v1.6

The `security` profile installs local pinned release binaries for Gitleaks, Trivy and Hadolint after SHA256 verification in addition to APT tools such as ShellCheck, shfmt and pre-commit. CI remains authoritative, but `doctor.sh --profile security --strict` should no longer require tools that the profile does not attempt to install.


## Release asset integrity

v1.6 verifies downloaded security tooling before installation and reinstalls the approved checksum-verified version even when a prior binary already exists. Gitleaks and Trivy archives are checked against their release checksum manifests. Hadolint's direct binary is checked against the release SHA256 file before it is installed into `/usr/local/bin`.
