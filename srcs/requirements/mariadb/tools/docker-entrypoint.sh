#!/bin/sh
set -e

DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

# Make sure the socket directory exists and belongs to mysql.
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# First run only: the system database exists only after the data dir is set up.
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[mariadb] First run: initialising the data directory."

    # Create the system tables. auth-root-method=normal lets root use a password.
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql \
        --auth-root-authentication-method=normal --skip-test-db >/dev/null

    # Run the setup SQL once in bootstrap mode (no networking), then it exits.
    # The EOF marker and the SQL lines must start at column 0 for the heredoc.
    mysqld --user=mysql --bootstrap <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
EOF

    echo "[mariadb] Initialisation finished."
else
    echo "[mariadb] Data directory already set up, skipping initialisation."
fi

# Start MariaDB in the foreground and hand PID 1 over to it.
exec mysqld --user=mysql
