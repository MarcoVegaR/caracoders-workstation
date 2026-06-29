# Docker Security

Docker group membership is high local privilege. A user who can control the Docker daemon can usually escalate on the workstation. The bootstrap therefore requires explicit confirmation before adding the current user to the `docker` group.

## Localhost bind policy

Published development ports must bind to `127.0.0.1` by default. Do not expose PostgreSQL, Redis, Mailpit, pgAdmin or local app ports to the LAN unless the project explicitly requires it and documents the reason.

## Exclusions

Docker Desktop and Portainer are not part of v1. Destructive cleanup such as `docker system prune` is never automatic.
