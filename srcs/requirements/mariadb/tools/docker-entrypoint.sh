# Makes the script stop immediately if any command fails.
set -e

DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

# Make sure the socket directory exists and belongs to mysql.
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# Check if the system data base already exist, or if we need to create a new one
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "First run: initialising the MariaDB data directory."

    # Create the system tables. auth-root-method=normal lets root log in with a password (not just the local socket)
    mariadb-install-db \
        --user=mysql \
        --datadir=/var/lib/mysql \
        --auth-root-authentication-method=normal \
        --skip-test-db > /dev/null

      # Pipe the setup SQL straight into mysqld in bootstrap mode.
      mysqld --user=mysql --bootstrap <<EOF
  ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
  CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
  CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
  GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
EOF

    # Run the SQL in bootstrap mode. --bootstrap starts mysqld just long enough
    # to read the SQL, with networking turned off, then it exits on its own.
    mysqld --user=mysql --bootstrap < /tmp/init.sql

    rm -f /tmp/init.sql

    echo " Initialisation finished."
else
    echo " Data directory already set up, skipping initialisation."
fi

# Start MariaDB in the foreground and hand PID 1 over to it.
#   exec   replaces this shell with mysqld, so mysqld itself becomes PID 1.
#   mysqld stays in the foreground by default
exec mysqld --user=mysql
