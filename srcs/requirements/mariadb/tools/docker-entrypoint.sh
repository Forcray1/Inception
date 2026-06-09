#!/bin/sh
# Prepares the database, then starts MariaDB as PID 1.
set -e

DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

# Show the values we will use, so the log makes any empty variable obvious.
echo "[mariadb] DB=[${MYSQL_DATABASE}] USER=[${MYSQL_USER}]"

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# Create the system tables only if they are missing.
if [ ! -d /var/lib/mysql/mysql ]; then
    echo "[mariadb] Creating system tables."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql \
        --auth-root-authentication-method=normal --skip-test-db >/dev/null
fi

# Create our database and user only if the database does not exist yet.
# IMPORTANT: this check uses the WordPress database, not the mysql system table.
# The system tables can be pre-created in the image and copied into the volume,
# but the WordPress database only ever exists once WE create it here. So this is
# the reliable "have we set up our stuff yet?" test.
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "[mariadb] Creating database '${MYSQL_DATABASE}' and user '${MYSQL_USER}'."
    # Bootstrap mode starts with --skip-grant-tables, so the privilege system is
    # off and ALTER/CREATE USER/GRANT fail with error 1290. FLUSH PRIVILEGES
    # first loads the grant tables and re-enables them, so the rest works.
    mysqld --user=mysql --bootstrap <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
    echo "[mariadb] Setup finished."
else
    echo "[mariadb] Database already present, skipping setup."
fi

# Start MariaDB in the foreground as PID 1.
exec mysqld --user=mysql
