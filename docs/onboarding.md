# Onboarding

Checklist for preparing a new Caracoders technician/developer workstation from zero.

## Base OS

1. Install Ubuntu 26.04 LTS on real hardware. Ubuntu 24.04 LTS is secondary when package availability allows it.
2. Apply system updates and reboot if the kernel or core packages changed:

```bash
sudo apt update
sudo apt upgrade
sudo reboot
```

## Workstation Standard

1. Install Git if the base image does not include it:

```bash
sudo apt install git
```

2. Clone the repository and enter it:

```bash
git clone <repo-url> caracoders-workstation
cd caracoders-workstation
```

3. Copy the local configuration example only when non-interactive or consent-controlled installation is needed:

```bash
cp .caracoders-workstation.env.example .caracoders-workstation.env
```

4. Review and edit `.caracoders-workstation.env`. It is ignored by Git and must not contain real secrets.
5. Run the dry-run first:

```bash
./bootstrap.sh --profile full --dry-run
```

6. Run the installer:

```bash
./bootstrap.sh --profile full
```

7. If Docker was installed or the user was added to the Docker group, log out and back in before Docker checks.
8. Validate the workstation:

```bash
./doctor.sh --profile full --strict
./verify.sh --profile full
```

## First Laravel Project

1. Create a project folder from the Laravel template:

```bash
mkdir my-app
cp -R templates/laravel/. my-app/
cd my-app
cp .env.example .env
cp Makefile.example Makefile
docker compose --env-file .env up -d --build
```

2. Open the project in VS Code:

```bash
code .
```

3. Reopen in the Dev Container when prompted, or use the command palette: `Dev Containers: Reopen in Container`.
4. Use OpenCode from the project root after reviewing the project `AGENTS` guidance and MCP policy.

## Operator Notes

- Keep runtime dependencies inside project Docker/Dev Container definitions whenever possible.
- Do not add local secrets to the workstation repo.
- Use `docs/troubleshooting.md` and `./doctor.sh --profile full --strict` before escalating setup issues.
