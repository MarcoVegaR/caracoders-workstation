# Laravel template

Official Caracoders Laravel v1 template.

- Docker Compose own template.
- Dev Container required.
- PostgreSQL as main database.
- Redis and Mailpit available for local development.
- No global database server is required on Ubuntu.

```bash
cp .env.example .env
cp Makefile.example Makefile
docker compose up -d --build
docker compose exec app composer install
docker compose exec app php artisan key:generate
docker compose exec app php artisan migrate
```

Open app at `http://localhost:8080` and Mailpit at `http://localhost:8025`.
