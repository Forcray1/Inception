FROM debian:bookworm

# apt-get update         | refreshes the list of available packages.
# -y                     | answers yes automatically, so the build is not stuck waiting for input.
# rm -rf .../apt/lists/* | deletes the downloaded package lists afterwards
RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/lib/mysql/*
# Empty the data dir the package pre-created at build time. Otherwise Docker
# copies it into the (empty) named volume on first mount, /var/lib/mysql/mysql
# then exists, and our entrypoint wrongly thinks the DB is already set up and
# skips the user/database creation.

# MariaDB needs this folder at runtime for its unix socket file.
RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

# Copy our server config into the directory MariaDB reads .cnf files from.
COPY conf/conf.cnf /etc/mysql/mariadb.conf.d/conf.cnf

# Copy our startup script into a folder that is on the PATH, then make it
# executable so it can be run as the entrypoint.
COPY tools/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 3306

# When the container starts, run our script.
ENTRYPOINT ["docker-entrypoint.sh"]
