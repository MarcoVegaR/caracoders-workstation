# Security Policy

`caracoders-workstation` is public and must never contain real secrets, production credentials, browser sessions, private SSH keys, API keys, tokens, database passwords or internal-only infrastructure details.

## Supported use

This repository is intended for Ubuntu workstations used by Caracoders developers and support technicians. It configures local development tooling and project templates. It is not a production server hardening repository.

## Reporting

Report security issues privately to the maintainers of Caracoders Pro Services C.A. Do not open public issues containing credentials, exploit chains, internal hostnames or screenshots exposing tokens.

## Design guardrails

- No global database servers are installed by default.
- No OpenSSH server is installed by default.
- No UFW rules are activated by this repository.
- MCP filesystem access is scoped by default.
- The Docker group is treated as a privileged local trust boundary.
- Gitleaks runs in CI.

## Bootstrap hardening

- Local `.caracoders-workstation.env` is parsed as data, not sourced as shell code.
- Bootstrap command execution uses argument arrays and avoids dynamic shell evaluation.
- Published template ports bind to `127.0.0.1` by default.
- CI treats Trivy HIGH/CRITICAL findings as blocking unless explicitly ignored with review.
