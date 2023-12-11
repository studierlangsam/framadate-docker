FROM alpine/git:v2.43.0 as CHECKOUT
ARG version
WORKDIR /var/www/framadate
RUN git clone https://framagit.org/framasoft/framadate/framadate.git . \
 && git checkout tags/$version
RUN rm -rf .git .editorconfig .gitignore .gitlab-ci.yml

FROM composer:2.6.6 as COMPOSER_INSTALL
COPY --from=CHECKOUT /var/www/framadate /var/www/framadate
WORKDIR /var/www/framadate
RUN apk add --no-cache icu-dev \
 && docker-php-ext-configure intl \
 && docker-php-ext-install intl \
 && composer install

FROM php:8.1.13-fpm-alpine3.15
WORKDIR /var/www/framadate
RUN apk add --no-cache --virtual envsubst-runtime libintl \
 && apk add --no-cache --virtual envsubst-getBuild gettext \
 && cp /usr/bin/envsubst /usr/local/bin/envsubst \
 && apk del envsubst-getBuild
RUN apk add --no-cache --virtual intl-runtime icu-dev \
 && apk add --no-cache --virtual mbstring-runtime oniguruma-dev \
 && docker-php-ext-configure intl \
 && docker-php-ext-install intl pdo pdo_mysql mbstring
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY php.conf/cookies.ini php.conf/timezone.ini $PHP_INI_DIR/conf.d/
COPY --from=COMPOSER_INSTALL /var/www/framadate /opt/www/framadate
COPY --from=COMPOSER_INSTALL /usr/bin/composer /usr/bin/composer
COPY config.php /opt/www/framadate/app/inc/
COPY bin/startup.sh /bin/startup
ENTRYPOINT ["/bin/startup"]
CMD ["php-fpm"]
