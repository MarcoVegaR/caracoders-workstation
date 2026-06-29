# Docker

Docker Engine is installed from Docker's official APT repository. Docker Compose is installed as the Docker Compose plugin. Docker Desktop and Portainer are outside v1.

## Docker group risk

Adding a user to the `docker` group grants high local privilege because that user can control the Docker daemon. The bootstrap therefore always treats this as a sensitive action. In `--yes` mode it is skipped unless `CARACODERS_CONFIRM_DOCKER_GROUP="true"` exists in the local ignored config.

## Published ports

Project templates bind host-published ports to `127.0.0.1` by default:

```yaml
ports:
  - "127.0.0.1:${APP_PORT:-8080}:80"
```

This keeps app, PostgreSQL, Redis, Mailpit and pgAdmin reachable from the workstation itself without exposing them to the LAN by accident. If a project needs LAN access, change the bind explicitly and document the operational reason.

## No destructive cleanup by default

The repo does not run `docker system prune` or destructive volume cleanup. Those actions require a separate, explicit maintenance procedure.

## Docker smoke image policy v1.6

The Docker smoke test uses `DOCKER_HELLO_WORLD_IMAGE` from `config/versions.env`. The installer rejects `:latest` and requires an image digest. This keeps the required `docker run hello-world`-style validation without silently drifting to a different image over time.


## Docker APT key policy v1.6

The installer follows Docker's official keyring/signed-by repository model, but does not write the downloaded key directly with `sudo curl`. It downloads the key to a temporary user-owned file, checks the fingerprint against `DOCKER_APT_KEY_FINGERPRINT` from `config/versions.env`, and only then installs it to `/etc/apt/keyrings/docker.asc`.
