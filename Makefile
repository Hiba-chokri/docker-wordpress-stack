NAME = inception
DATA_DIR = /home/hichokri/data

all: build up

build:
	@mkdir -p $(DATA_DIR)/wordpress
	@mkdir -p $(DATA_DIR)/mariadb
	docker-compose -f srcs/docker-compose.yml build

up:
	docker-compose -f srcs/docker-compose.yml up -d

down:
	docker-compose -f srcs/docker-compose.yml down

clean: down
	docker-compose -f srcs/docker-compose.yml down -v --rmi all

fclean: clean
	@sudo rm -rf $(DATA_DIR)

re: fclean all

.PHONY: all build up down clean fclean re
