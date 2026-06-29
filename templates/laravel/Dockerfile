ARG NODE_IMAGE=node:24.18.0-bookworm-slim@sha256:862263c612aa437e3037674b85419622a9d93bff80aa1eee5398dfe686375532
ARG COMPOSER_IMAGE=composer:2.10.1@sha256:c883af18892268b3b8369c4a39c08f80b393383e79d80b75140a3ea489dbbb78
ARG PHP_IMAGE=php:8.4-fpm-bookworm@sha256:d39ec536545f1f698dc971cd2a0a77424867a27a992dd43b8e82d5cf112b02cb

FROM ${NODE_IMAGE} AS node
FROM ${COMPOSER_IMAGE} AS composer
FROM ${PHP_IMAGE}

ARG UID=1000
ARG GID=1000
ARG PECL_REDIS_VERSION=6.2.0

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/bin/npm /usr/local/bin/npm
COPY --from=node /usr/local/bin/npx /usr/local/bin/npx
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      git \
      curl \
      unzip \
      zip \
      libpq-dev \
      libzip-dev \
      libicu-dev \
      libonig-dev \
      libxml2-dev \
    && docker-php-ext-install pdo pdo_pgsql intl zip bcmath opcache \
    && pecl install redis-${PECL_REDIS_VERSION} \
    && docker-php-ext-enable redis \
    && npm install -g pnpm@11.9.0 \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g "${GID}" app \
    && useradd -u "${UID}" -g app -m -s /bin/bash app

WORKDIR /var/www/html
USER app

CMD ["php-fpm"]
