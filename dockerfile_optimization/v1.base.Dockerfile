ARG VERSION=7.2

FROM php:${VERSION}-fpm-alpine

## Install
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

## Copy project files to workdir
COPY . .

## Install composer dependencies
RUN composer install --no-interaction --optimize-autoloader

## Change files owner to php-fpm default user
RUN chown -R www-data:www-data /app /var/log /var/run /usr/local/etc /run && chmod -R 777 /app/web /app/src
