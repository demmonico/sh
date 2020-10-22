FROM testsize-php-1:base

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
