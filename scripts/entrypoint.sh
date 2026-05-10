#!/usr/bin/env bash
set -euo pipefail

: "${OPENCART_HTTP_SERVER:=http://localhost:${PORT:-8080}/}"
: "${OPENCART_ADMIN_USER:=demo_admin}"
: "${OPENCART_ADMIN_PASSWORD:=demo_password}"
: "${OPENCART_ADMIN_EMAIL:=demo@junopayserver.com}"
: "${OPENCART_DB_NAME:=opencart}"
: "${OPENCART_DB_USER:=opencart}"
: "${OPENCART_DB_PASSWORD:=opencart}"
: "${JUNOPAY_BASE_URL:=}"
: "${JUNOPAY_MERCHANT_API_KEY:=}"
: "${JUNOPAY_WEBHOOK_SECRET:=demo-webhook-secret}"

if [[ -n "${PORT:-}" && "${PORT}" != "8080" ]]; then
  sed -ri "s/Listen [0-9]+/Listen ${PORT}/" /etc/apache2/ports.conf
  sed -ri "s/<VirtualHost \\*:[0-9]+>/<VirtualHost *:${PORT}>/" /etc/apache2/sites-available/000-default.conf
fi

mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

if [[ ! -d /var/lib/mysql/mysql ]]; then
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
fi

mysqld_safe --datadir=/var/lib/mysql --skip-grant-tables --skip-networking=0 --bind-address=127.0.0.1 &
mysql_pid="$!"

for _ in $(seq 1 60); do
  if mysqladmin ping -h 127.0.0.1 --silent; then
    break
  fi
  sleep 1
done

mysql -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`${OPENCART_DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
SQL

if ! mysql -h 127.0.0.1 -u"${OPENCART_DB_USER}" -p"${OPENCART_DB_PASSWORD}" "${OPENCART_DB_NAME}" -e "SHOW TABLES LIKE 'oc_setting';" | grep -q oc_setting; then
  php /var/www/html/install/cli_install.php install \
    --db_hostname 127.0.0.1 \
    --db_username "${OPENCART_DB_USER}" \
    --db_password "${OPENCART_DB_PASSWORD}" \
    --db_database "${OPENCART_DB_NAME}" \
    --db_driver mysqli \
    --db_port 3306 \
    --username "${OPENCART_ADMIN_USER}" \
    --password "${OPENCART_ADMIN_PASSWORD}" \
    --email "${OPENCART_ADMIN_EMAIL}" \
    --http_server "${OPENCART_HTTP_SERVER}"
fi

rm -rf /var/www/html/install

php /usr/local/bin/seed-demo.php

chown -R www-data:www-data /var/www/html

if [[ -z "${JUNOPAY_MERCHANT_API_KEY}" ]]; then
  echo "warning: JUNOPAY_MERCHANT_API_KEY is not set; checkout invoice creation will fail until configured" >&2
fi

exec apache2-foreground
