# Stop immediately if any command fails.
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

# php-fpm needs this folder
mkdir -p /run/php

cd /var/www/html

# Wait until MariaDB is reachable AND our user can log in.
# Ends as soon as the DB answers.
echo "[wordpress] Waiting for MariaDB to be ready..."
until mariadb -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$DB_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; do
    sleep 1
done
echo "[wordpress] MariaDB is ready."

if [ ! -f wp-config.php ]; then
    echo "[wordpress] Installing WordPress..."

    # Download the WordPress core files into the current folder.
    wp core download --allow-root

    # Create wp-config.php with the database connection details
    wp config create --allow-root \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost="$MYSQL_HOST"

    # Install the site and create the ADMIN user. The admin name comes from
    # .env (it must not contain "admin"), the password from the secret file.
    wp core install --allow-root \
        --url="$WP_URL" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email

    wp user create "$WP_USER" "$WP_USER_EMAIL" --allow-root \
        --role=author \
        --user_pass="$WP_USER_PASSWORD"

    echo "[wordpress] Installation finished."
else
    echo "[wordpress] Already installed, skipping setup."
fi

# Give the files to the web server user so php-fpm can read and write them.
chown -R www-data:www-data /var/www/html

#   exec  replaces this shell with php-fpm, so php-fpm becomes PID 1 and gets
#         signals directly, letting Docker restart it on crash.
#   -F    runs php-fpm in the foreground (no daemon).
exec /usr/sbin/php-fpm8.2 -F
