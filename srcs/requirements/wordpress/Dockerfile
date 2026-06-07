FROM debian:bookworm

#   php8.2-fpm                     the FastCGI process manager that runs PHP
#   php8.2-mysql                   lets PHP/WordPress talk to MariaDB
#   php8.2-curl/gd/mbstring/xml/zip  extensions WordPress expects, avoids warnings
#   curl                          used below to download wp-cli
#   mariadb-client                used by the entrypoint to wait for the database
RUN apt-get update && apt-get install -y \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-curl \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-zip \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Install wp-cli, the command-line tool used to install and configure WordPress
# without the browser wizard.
RUN curl -o /usr/local/bin/wp \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# Replace the php-fpm pool config so php-fpm listens on the network instead of
# a local socket, so nginx in another container can reach it.
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# php-fpm needs this folder to exist at runtime.
RUN mkdir -p /run/php

# Copy the startup script in and make it executable.
COPY tools/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Work inside the WordPress files folder.
WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["docker-entrypoint.sh"]
