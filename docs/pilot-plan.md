# Pilot plan

Use this plan before installing a release candidate across many Caracoders machines.

## Scope

- Pilot on 1 or 2 representative Ubuntu machines before mass rollout.
- Prefer one clean install and one existing developer/support workstation when available.
- Do not use production-only machines as the first pilot target.

## Steps

1. Confirm the release ZIP or Git commit hash being tested.
2. Clone the repo on the pilot machine:

```bash
git clone <repo-url> caracoders-workstation
cd caracoders-workstation
```

3. Run the dry-run and save observations:

```bash
./bootstrap.sh --profile full --dry-run
```

4. Run the installer:

```bash
./bootstrap.sh --profile full
```

5. Log out and back in if Docker group membership changed.
6. Run validations:

```bash
./doctor.sh --profile full --strict
./verify.sh --profile full
```

7. Create a Laravel project from the template and confirm Docker Compose, VS Code Dev Containers and OpenCode can be used from the project root.
8. Record failures, manual workarounds, package conflicts, network/proxy issues and elapsed install time.

## Pass Criteria

- Dry-run is understandable and does not imply actions that the real install will skip.
- Bootstrap completes without unreviewed manual changes.
- Doctor passes in strict mode after required logout/login.
- Verify passes from the repo root.
- Laravel template starts successfully and binds exposed services to localhost by default.
- VS Code and OpenCode are usable for a normal project workflow.

## Rollout Decision

Promote the candidate only after pilot issues are either fixed, explicitly accepted or documented as known limitations. If a sensitive installer fails or requires manual security bypasses, stop rollout and prepare a bugfix release candidate.
