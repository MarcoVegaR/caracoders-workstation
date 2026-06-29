# Laravel

Laravel is the first officially supported project environment.

## Host scope

The host installs productivity tools only:

- PHP CLI and Laravel-relevant CLI extensions.
- Composer.
- Laravel Installer using the approved Composer constraint from `config/versions.env`.
- Node through NVM using the approved Node version.
- npm and pinned pnpm.
- `psql` client and Redis CLI.

The host does not install PostgreSQL Server, MySQL Server, Redis Server, Nginx, Apache, PHP-FPM, Sail or DDEV.

## Container scope

The Laravel template provides PostgreSQL, Redis, Mailpit, Nginx and PHP-FPM in containers. Published ports bind to `127.0.0.1` by default.

## Template purpose

`templates/laravel` is a runtime template for a Laravel project workspace. It is not a complete Laravel application by itself. Use it by copying the template into a new or existing Laravel project and then adapting project-specific `.env`, migrations, package files and application code.
