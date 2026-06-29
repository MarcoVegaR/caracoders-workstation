# pgAdmin

pgAdmin runs as a local container using `templates/pgadmin`, exposed at `http://localhost:5050` by default.

The template binds to `127.0.0.1` only and uses example credentials. It is for local development, not production. Real secrets must go in a local ignored `.env` file or a secret manager, never in this repository.
