# Project AGENTS

- Runtime is Docker Compose + Dev Container.
- PostgreSQL is the default database.
- Do not add Laravel Sail or DDEV.
- Do not commit `.env` or local credentials.
- Use `docker compose` or the Dev Container terminal for project commands.

## Verification

```bash
docker compose ps
php artisan test
npm run build
```
