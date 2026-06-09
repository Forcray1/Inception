_This project has been created as part of the 42 curriculum by mlorenzo._

# Inception

## Description

Inception is a system administration project. The goal is to build a small web
infrastructure from scratch using Docker, where each service runs in its own
container, the images are built from hand-written Dockerfiles, and everything is
started together with Docker Compose.

The stack is made of three services:

- NGINX: the only entry point, serving HTTPS on port 443 with TLS 1.2 or 1.3.
- WordPress with php-fpm: the website, with no web server of its own.
- MariaDB: the database, reachable only from inside the private network.

The website data is kept in two Docker named volumes (the database and the
website files), both stored under /home/mlorenzo/data on the host. The
containers communicate over a private Docker network and restart automatically
if they crash.

## Instructions

Prerequisites: a Linux machine (a virtual machine is required for this project)
with Docker and Docker Compose installed, and the domain mapped locally. Add
this line to /etc/hosts:

    127.0.0.1 mlorenzo.42.fr

Before the first run, create the secret files (they are not stored in git). In
the secrets folder, create one file per password, each containing only the
password:

    secrets/db_root_password.txt
    secrets/db_password.txt
    secrets/wp_admin_password.txt
    secrets/wp_user_password.txt

Then, from the root of the repository:

    make            build the images and start the stack
    make down       stop and remove the containers
    make re         rebuild everything from scratch
    make fclean     remove everything, including the saved data
    make status     show the state of the containers
    make logs       follow the logs

Open https://mlorenzo.42.fr in a browser (accept the self-signed certificate
warning). The administration panel is at https://mlorenzo.42.fr/wp-admin.

## Project description

### Use of Docker and the sources

The project is organised as the subject requires. The srcs folder holds the
docker-compose.yml, the .env file, and a requirements folder with one subfolder
per service (mariadb, nginx, wordpress). Each service subfolder has its own
Dockerfile, its configuration in a conf folder, and its startup script in a
tools folder. The Makefile at the root drives docker-compose.yml, which builds
every image from these Dockerfiles. No image is pulled ready-made; only the
Debian base image is used.

### Main design choices

- Base image: Debian bookworm, the penultimate stable version. No image uses the
  latest tag.
- Each container runs a single process in the foreground as PID 1 (mysqld,
  php-fpm, and nginx with daemon off). There is no tail -f or similar hack.
- Passwords are provided through Docker secrets, mounted as files under
  /run/secrets. Non-secret configuration (domain, database name, user names) is
  in the .env file.
- The two persistent storages are Docker named volumes whose data is stored in
  /home/mlorenzo/data on the host.
- NGINX is the only published entry point, on port 443, using TLS 1.2 or 1.3.

### Required comparisons

Virtual Machines vs Docker. A virtual machine runs a full guest operating system
on virtualised hardware through a hypervisor. It is well isolated but heavy: it
boots slowly and uses a lot of memory. A Docker container shares the host kernel
and isolates only at the process level, so it is much lighter and starts in
milliseconds, at the cost of weaker isolation.

Secrets vs Environment Variables. Environment variables are convenient for
non-sensitive configuration, but they appear in docker inspect and in the
process environment, so they leak easily. Docker secrets are mounted as files
that do not show up in the environment or in docker inspect, which is why the
passwords in this project are handled as secrets, not as environment variables.

Docker Network vs Host Network. A user-defined Docker network isolates the
containers and gives them a private DNS, so they reach each other by service
name (for example, wordpress reaches the database at the host "mariadb"). The
host network would remove that isolation and put the containers directly on the
host's network, which is forbidden by the subject.

Docker Volumes vs Bind Mounts. A named volume is managed by Docker and
referenced by name, which is portable and is what the subject requires. A bind
mount maps an arbitrary host path directly into a container. This project uses
named volumes; their data is placed under /home/mlorenzo/data using the local
driver, so they stay named volumes while meeting the required storage location.

## Resources

- Docker documentation: https://docs.docker.com/
- Docker Compose documentation: https://docs.docker.com/compose/
- The official NGINX, php-fpm, MariaDB and wp-cli documentation.

### AI Usage:
- AI was used as a learning and explanation tool, and to help compose the README, and the documentation.

## Walkthrough

This section lists, in order, the commands used to verify the project and the
output you should expect.

### 0. Clean the machine first

Run the reset command from the evaluation sheet in an empty directory before
cloning, so nothing is left from a previous run:

    docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null

Expected: the three default networks (`bridge`, `host`, `none`) cannot be
removed and print an error; everything else is gone. Confirm with:

    docker ps -a        # expected: empty (only the header line)
    docker images -qa   # expected: empty
    docker volume ls    # expected: empty (only the header line)

### 1. Static checks (before building)

No forbidden directives in the compose file or anywhere Docker is used:

    grep -nE "network:\s*host|links:|--link" srcs/docker-compose.yml Makefile srcs/requirements/*/Dockerfile
    # expected: no output

Networks are present in the compose file:

    grep -n "networks" srcs/docker-compose.yml
    # expected: shows the per-service "networks:" keys and the top-level "networks:" block

No background process or infinite loop in the Dockerfiles or scripts:

    grep -nE "tail -f|sleep infinity" srcs/requirements/*/tools/*.sh srcs/requirements/*/Dockerfile
    # expected: no output

Base image is the penultimate stable Debian (bookworm), one Dockerfile per
service, none empty:

    grep -n "^FROM" srcs/requirements/*/Dockerfile
    # expected: each line is "FROM debian:bookworm"

Image name equals service name:

    grep -nE "^\s+(image|container_name):" srcs/docker-compose.yml
    # expected: image and service/container names match (mariadb, wordpress, nginx)

No secrets are tracked in git:

    git ls-files srcs/.env secrets/*.txt
    # expected: no output (only secrets/.gitkeep and srcs/.env_ex should be tracked)

### 2. Build and start

The domain must resolve locally first:

    grep mlorenzo.42.fr /etc/hosts
    # expected: 127.0.0.1 mlorenzo.42.fr

Create the four secret files (one password per file, no newline issues), then
build and start the stack from the repository root:

    make
    # expected: images build with no error, then the three containers start

Check container state:

    docker compose -f srcs/docker-compose.yml ps
    # expected: mariadb, wordpress, nginx all "Up"; mariadb shows "(healthy)"

### 3. Network

    docker network ls | grep inception
    # expected: a "inception" bridge network is listed

### 4. NGINX with SSL/TLS

Port 80 must be refused, port 443 must serve over TLS 1.2/1.3:

    curl -I http://mlorenzo.42.fr/
    # expected: connection refused / fails (nothing listens on 80)

    curl -kIv https://mlorenzo.42.fr/ 2>&1 | grep -iE "SSL connection using|TLSv1|HTTP/"
    # expected: TLSv1.2 or TLSv1.3, and "HTTP/1.1 200 OK"

In a browser, open https://mlorenzo.42.fr — expected: the configured WordPress
site (NOT the WordPress installation wizard). The self-signed certificate
warning is normal.

### 5. WordPress + php-fpm + volume

    docker compose -f srcs/docker-compose.yml ps wordpress
    # expected: container "Up"

    grep -i nginx srcs/requirements/wordpress/Dockerfile
    # expected: no output (no nginx in the wordpress image)

    docker volume inspect wordpress | grep -i device
    # expected: "device": "/home/mlorenzo/data/wordpress"

In the browser: log in at https://mlorenzo.42.fr/wp-admin with the admin
account, edit a page, and confirm the change shows on the site. Post a comment
with the non-admin user. All expected to work.

### 6. MariaDB + volume

    docker compose -f srcs/docker-compose.yml ps mariadb
    # expected: container "Up (healthy)"

    grep -i nginx srcs/requirements/mariadb/Dockerfile
    # expected: no output

    docker volume inspect mariadb | grep -i device
    # expected: "device": "/home/mlorenzo/data/mariadb"

The database exists and is not empty:

    docker exec -it mariadb mariadb -u root -p"$(cat secrets/db_root_password.txt)" -e "SHOW DATABASES; USE wordpress; SHOW TABLES;"
    # expected: the "wordpress" database is listed and contains wp_* tables

### 7. Persistence

Reboot the virtual machine, then from the repository root:

    docker compose -f srcs/docker-compose.yml up -d
    # expected: containers start again with no rebuild needed

Reopen https://mlorenzo.42.fr — expected: the page edit and the comment made
earlier are still there, and no installation wizard appears.

## Changes Log

Changes made after the initial implementation, with the reason for each.

- Restored the #!/bin/sh shebang at the top of the mariadb and wordpress
  entrypoint scripts.
- Added php8.2-cli to the wordpress image, because wp-cli needs a PHP
  command-line interpreter to run and php-fpm does not provide one.
- Added a healthcheck to the mariadb service and made wordpress wait for it with
  condition: service_healthy, for reliable startup ordering.
- Added try_files $uri =404; to the nginx PHP location, so only existing PHP
  files are executed (this blocks a known upload-and-execute attack).
