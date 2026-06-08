_This project has been created as part of the 42 curriculum by mlorenzo._

# Inception



## Description



## Instructions



## Project description

### Use of Docker and the sources



### Main design choices



### Required comparisons



## Resources

- Docker documentation: https://docs.docker.com/
- Docker Compose documentation: https://docs.docker.com/compose/
- The official NGINX, php-fpm, MariaDB and wp-cli documentation.


Added`#!/bin/sh`

Added a `healthcheck` to the mariadb service, and changed the wordpress
service `depends_on` to wait for `mariadb` with `condition: service_healthy`.

Added `try_files $uri =404;` to the `location ~ \.php$` block in
`srcs/requirements/nginx/conf/nginx.conf`.
