# Inception Infrastructure Makefile
# Manages Docker-based web hosting environment

NAME = inception
USER = hichokri
DATA_DIR = /home/$(USER)/data
COMPOSE_FILE = srcs/docker-compose.yml

# Default target
all: build up

# Build target: create data directories and build Docker images
build:
	@echo "Creating data directories..."
	@mkdir -p $(DATA_DIR)/wordpress
	@mkdir -p $(DATA_DIR)/mariadb
	@echo "Building Docker images..."
	docker-compose -f $(COMPOSE_FILE) build

# Start containers in detached mode
up:
	@echo "Starting containers..."
	docker-compose -f $(COMPOSE_FILE) up -d

# Stop containers
down:
	@echo "Stopping containers..."
	docker-compose -f $(COMPOSE_FILE) down

# Clean: remove containers, volumes, and images
clean: down
	@echo "Removing containers, volumes, and images..."
	docker-compose -f $(COMPOSE_FILE) down -v --rmi all

# Full clean: also remove host data directories
fclean: clean
	@echo "Removing host data directories..."
	@rm -rf $(DATA_DIR)

# Full rebuild
re: fclean all

.PHONY: all build up down clean fclean re
