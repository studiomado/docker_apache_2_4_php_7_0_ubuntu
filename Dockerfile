FROM ubuntu:16.04

MAINTAINER alessandro.minoccheri@studiomado.it

ENV OS_LOCALE="it_IT.UTF-8"
RUN apt-get update && apt-get install -y locales && locale-gen ${OS_LOCALE}
ENV LANG=${OS_LOCALE} \
    LANGUAGE=${OS_LOCALE} \
    LC_ALL=${OS_LOCALE} \
    DEBIAN_FRONTEND=noninteractive

ENV APACHE_CONF_DIR=/etc/apache2 \
    PHP_CONF_DIR=/etc/php/7.0 \
    PHP_DATA_DIR=/var/lib/php

RUN \
    BUILD_DEPS='software-properties-common python-software-properties' \
    && dpkg-reconfigure locales \
    && apt-get install --no-install-recommends -y $BUILD_DEPS \
    && add-apt-repository -y ppa:ondrej/php \
    && add-apt-repository -y ppa:ondrej/apache2 \
    && apt-get update \
    && apt-get install -y curl apache2 libapache2-mod-php7.0 php7.0-cli php7.0-readline php7.0-mbstring php7.0-zip php7.0-intl php7.0-xml php7.0-json php7.0-curl php7.0-mcrypt php7.0-gd php7.0-pgsql php7.0-mysql php-pear \
    # Apache settings
    && cp /dev/null ${APACHE_CONF_DIR}/conf-available/other-vhosts-access-log.conf \
    && rm ${APACHE_CONF_DIR}/sites-enabled/000-default.conf ${APACHE_CONF_DIR}/sites-available/000-default.conf \
    && a2enmod rewrite php7.0 \
    # PHP settings
    && phpenmod mcrypt \
    # Install composer
    && curl -sS https://getcomposer.org/installer | php -- --version=1.6.4 --install-dir=/usr/local/bin --filename=composer \
    # Cleaning
    && apt-get purge -y --auto-remove $BUILD_DEPS \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    # Forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stderr /var/log/apache2/error.log \
    && chown www-data:www-data ${PHP_DATA_DIR} -Rf

EXPOSE 80 9000

ENTRYPOINT service apache2 start && bash