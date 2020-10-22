ARG VERSION=7.2



##### DEV image #####
FROM testsize-php-4:base AS dev

# install xdebug for phpunit test coverage
RUN apk add --no-cache $PHPIZE_DEPS \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug

## Copy php default config
ARG PHP_ENV=dev
COPY ./docker/php-fpm/conf.d/default-${PHP_ENV}.ini /usr/local/etc/php/conf.d/default.ini
COPY ./docker/php-fpm/conf.d/www.conf /usr/local/etc/php-fpm.d/www.conf

## Cleanup
RUN apk del dev-deps && \
    composer global remove hirak/prestissimo && \
    rm /usr/local/bin/composer



##### PROD image #####
FROM testsize-php-4:base AS prod

WORKDIR /usr/lib

## Install newrelic agent
RUN export NEWRELIC_VERSION=$(curl -sS https://download.newrelic.com/php_agent/release/ | sed -n 's/.*>\(.*linux-musl\).tar.gz<.*/\1/p') && \
    curl -sS https://download.newrelic.com/php_agent/release/${NEWRELIC_VERSION}.tar.gz | gzip -dc | tar xf - && \
    NR_INSTALL_SILENT=true ./${NEWRELIC_VERSION}/newrelic-install install

WORKDIR /app

## Copy php default config
ARG PHP_ENV=prod
COPY ./docker/php-fpm/conf.d/default-${PHP_ENV}.ini /usr/local/etc/php/conf.d/default.ini
COPY ./docker/php-fpm/conf.d/www.conf /usr/local/etc/php-fpm.d/www.conf

## Cleanup
RUN apk del dev-deps && \
    composer global remove hirak/prestissimo && \
    rm /usr/local/bin/composer



##### BASE image #####
FROM php:${VERSION}-fpm-alpine AS base

RUN \
  # system dependencies
  apk update && \
    apk add --no-cache --virtual build-deps tzdata && \
    apk add --no-cache --virtual dev-deps git && \
  # php extensions
  docker-php-ext-install \
    pdo_mysql \
    bcmath \
    opcache && \
  # composer
  wget https://getcomposer.org/installer && \
    php installer --install-dir=/usr/local/bin/ --filename=composer && \
    composer global require hirak/prestissimo && \
  # cleanup
  apk del build-deps && \
      rm installer

WORKDIR /app
COPY . .

RUN composer install --no-interaction --optimize-autoloader

## Change files owner to php-fpm default user
RUN chown -R www-data:www-data /app /var/log /var/run /usr/local/etc /run && chmod -R 777 /app/web /app/src
