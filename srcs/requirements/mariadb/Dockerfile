FROM debian:bookworm

# apt-get update         | refreshes the list of available packages.
# -y                     | answers yes automatically, so the build is not stuck waiting for input.
# rm -rf .../apt/lists/* | deletes the downloaded package lists afterwards
RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/apt/lists/* && \
	rm -rf /var/lib/mysql/*

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
