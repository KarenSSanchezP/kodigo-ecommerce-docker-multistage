# syntax=docker/dockerfile:1.7
# Base única con las extensiones que necesita Laravel.
FROM php:8.4-fpm-alpine AS php-base
RUN set -eux; \
    apk add --no-cache icu-libs libzip oniguruma libxml2; \
    apk add --no-cache --virtual .build-deps $PHPIZE_DEPS icu-dev libzip-dev oniguruma-dev; \
    docker-php-ext-install -j"$(nproc)" pdo_mysql mbstring bcmath intl zip; \
    apk del .build-deps; \
    cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
WORKDIR /var/www/html

# Etapa 1: vendor se reconstruye solamente cuando cambian los archivos de Composer.
FROM php-base AS vendor
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_CACHE_DIR=/tmp/composer-cache
COPY composer.json composer.lock ./
RUN --mount=type=cache,target=/tmp/composer-cache \
    composer install --no-dev --no-scripts --prefer-dist --no-interaction \
    --no-progress --optimize-autoloader

# Etapa 2: integrar el código, optimizar autoload y descubrir proveedores.
FROM php-base AS build
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1
COPY --from=vendor /var/www/html/vendor ./vendor
COPY . .
RUN composer dump-autoload --no-dev --optimize --no-scripts --no-interaction \
    && php artisan package:discover --ansi \
    && mkdir -p storage/logs storage/framework/cache/data storage/framework/views \
       storage/framework/sessions bootstrap/cache

# Etapa 3: PHP-FPM sin Composer, compiladores ni dependencias de desarrollo.
FROM php-base AS runner
COPY --from=build --chown=www-data:www-data /var/www/html /var/www/html
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R ug+rwX storage bootstrap/cache
USER www-data
EXPOSE 9000
CMD ["php-fpm", "-F"]
