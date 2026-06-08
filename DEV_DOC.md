# Developer documentation

This document explains how to set up, build, run, and manage the Inception
project as a developer.

## Set up the environment from scratch

Prerequisites:

- A Linux machine. This project must run in a virtual machine.
- Docker and the Docker Compose plugin installed.
- make.
- The domain mapped locally: add "127.0.0.1 mlorenzo.42.fr" to /etc/hosts.

Configuration files:

- srcs/.env holds the non-secret configuration: the domain, the database name
  and user, the WordPress account names and emails, the site title and URL. It
  contains no passwords.
- The secrets folder holds one password per file. These files are ignored by
  git, so you create them yourself before the first build:

    secrets/db_root_password.txt    MariaDB root password
    secrets/db_password.txt         WordPress database user password
    secrets/wp_admin_password.txt   WordPress admin account password
    secrets/wp_user_password.txt    WordPress second user password

  Each file must contain only the password, with no comments or quotes.

The Makefile creates the host folders for the volumes automatically
(/home/mlorenzo/data/mariadb and /home/mlorenzo/data/wordpress).

## Build and launch

    make build    build the images (runs every Dockerfile through compose)
    make up       start the containers in the background
    make          do both (default target)

The Makefile only ever runs srcs/docker-compose.yml, which builds the mariadb,
wordpress and nginx images from srcs/requirements/<service>/Dockerfile.

## Manage the containers and volumes

    make status      list the containers and their state
    make logs        follow the logs of all containers
    make down        stop and remove containers and the network
    make stop        pause the containers
    make start       resume the containers
    make clean       remove containers, network, images and volumes
    make fclean      clean, then delete the host data
    make re          rebuild everything from scratch

    docker exec -it mariadb sh                    open a shell inside a container
    docker compose -f srcs/docker-compose.yml ps  container state
    docker network ls                             list networks (look for "inception")
    docker volume ls                              list named volumes (mariadb, wordpress)
    docker volume inspect mariadb                 show the volume details, including the
                                                  device path under /home/mlorenzo/data

To log into the database from inside the mariadb container:

    docker exec -it mariadb mariadb -u wp_user -p
    (enter the password from secrets/db_password.txt)
    then run: SHOW DATABASES;   the wordpress database should be listed

## Where the data is stored and how it persists

The project uses two Docker named volumes:

- mariadb: backs /var/lib/mysql in the mariadb container; its data is stored on
  the host in /home/mlorenzo/data/mariadb.
- wordpress: backs /var/www/html; its data is stored on the host in
  /home/mlorenzo/data/wordpress, and is shared (read-only) with the nginx
  container so it can serve the files.

Both are named volumes whose data is placed in /home/mlorenzo/data using the
local driver. You can confirm this with "docker volume inspect mariadb": the
device option points to /home/mlorenzo/data/mariadb.

The data survives "make down" followed by "make up", and a reboot of the
machine, because it lives on the host, not inside the containers. The command
"make fclean" deletes the host data folders, so it is destructive and resets the
site to a fresh install on the next build.
