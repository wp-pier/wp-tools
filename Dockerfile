FROM composer:1.5 as composer
FROM wordpress:cli-1.4.0-php7.1 as wp-cli
FROM wppier/cron:latest as cron
FROM wppier/wp-fpm:latest

# install wp-cli dependencies
RUN apk add --no-cache \
    less               \
    mysql-client       \
    bash

COPY mo /usr/local/bin/mo
COPY src /usr/local/share/src
COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY --from=wp-cli  /usr/local/bin/wp /usr/local/bin/wp
COPY --from=cron /usr/local/bin/supercronic /usr/local/bin/supercronic
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY defaults.env /usr/local/etc/defaults.env
COPY cron /etc/supercronic/cron

USER www-data

LABEL name="wppier/wp-tool"
LABEL version="latest"

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["supercronic", "/etc/supercronic/cron"]
