# Newer Docker uses "docker compose" (with a space). If the machine has
# the old version, change DC to use "docker-compose" (with a hyphen).

NAME    = inception
COMPOSE = srcs/docker-compose.yml
DC      = docker compose -f $(COMPOSE)

# The host folders that back the two named volumes.
DATA_DIR = /home/mlorenzo/data
DB_DIR   = $(DATA_DIR)/mariadb
WP_DIR   = $(DATA_DIR)/wordpress

# Build the images, then start the containers in background.
all: build up

# Create the host folders the named volumes need.
dirs:
	mkdir -p $(DB_DIR) $(WP_DIR)

# Build images.
build: dirs
	$(DC) build

# Start the containers in background.
up: dirs
	$(DC) up -d

down:
	$(DC) down

stop:
	$(DC) stop

start:
	$(DC) start

status:
	$(DC) ps

logs:
	$(DC) logs -f

clean: down
	$(DC) down --rmi all --volumes --remove-orphans

fclean:
	-$(DC) down --rmi all --volumes --remove-orphans
	sudo rm -rf $(DATA_DIR)
	docker image prune -f

re: fclean all

.PHONY: all dirs build up down stop start status logs clean fclean re
