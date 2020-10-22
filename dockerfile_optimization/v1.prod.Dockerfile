FROM testsize-php-1:base

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
