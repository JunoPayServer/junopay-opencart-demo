FROM php:8.2-apache

ARG OPENCART_VERSION=3.0.5.0
ARG JUNOPAY_OPENCART_PLUGIN_REF=4f058d4b3fd004c1b973d73f62e07a226e423d4e

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip curl mariadb-server mariadb-client libpng-dev libjpeg-dev libzip-dev libicu-dev \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install gd mysqli zip intl \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/opencart.zip "https://github.com/opencart/opencart/releases/download/${OPENCART_VERSION}/opencart-${OPENCART_VERSION}.zip" \
    && unzip -q /tmp/opencart.zip -d /tmp/opencart \
    && cp -a /tmp/opencart/upload/. /var/www/html/ \
    && cp /var/www/html/config-dist.php /var/www/html/config.php \
	    && cp /var/www/html/admin/config-dist.php /var/www/html/admin/config.php \
	    && rm -rf /tmp/opencart /tmp/opencart.zip

RUN curl -fsSL -o /tmp/junopay-opencart-plugin.tar.gz "https://github.com/JunoPayServer/junopay-opencart-plugin/archive/${JUNOPAY_OPENCART_PLUGIN_REF}.tar.gz" \
    && mkdir -p /tmp/junopay-opencart-plugin \
    && tar -xzf /tmp/junopay-opencart-plugin.tar.gz -C /tmp/junopay-opencart-plugin --strip-components=1 \
    && cp -a /tmp/junopay-opencart-plugin/. /var/www/html/ \
    && rm -rf /tmp/junopay-opencart-plugin /tmp/junopay-opencart-plugin.tar.gz
COPY scripts/entrypoint.sh /usr/local/bin/junopay-opencart-entrypoint
COPY scripts/seed-demo.php /usr/local/bin/seed-demo.php

RUN chmod +x /usr/local/bin/junopay-opencart-entrypoint \
    && sed -ri "s/Listen 80/Listen 8080/" /etc/apache2/ports.conf \
    && sed -ri "s/<VirtualHost \*:80>/<VirtualHost *:8080>/" /etc/apache2/sites-available/000-default.conf \
    && mkdir -p /var/run/mysqld \
    && chown -R www-data:www-data /var/www/html /var/lib/mysql /var/run/mysqld

EXPOSE 8080

ENTRYPOINT ["junopay-opencart-entrypoint"]
