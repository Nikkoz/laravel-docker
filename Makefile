#!/usr/bin/make

SHELL=/bin/bash -e

APP_CONTAINER_NAME := app
NODE_CONTAINER_NAME := node

include docker.env
export $(shell sed 's/=.*//' docker.env)

ifeq "@docker" ""
	docker_message ?= "\n No docker installed"
	exit1
endif

ifeq "@docker-compose" ""
	docker_message += "\n No docker-compose installed"
	exit1
endif

ifndef VIRTUAL_HOST
$(error The VIRTUAL_HOST variable is missing.)
endif

ifndef COMPOSE_PROJECT_NAME
$(error The COMPOSE_PROJECT_NAME variable is missing.)
endif

exit1: ## exit
	@echo $(docker_message)
	@echo "\n exiting"
	kill 2

laravel-install:
	@echo -e "Make: Installing Laravel instance...\n"
	@make -s up
	@make -s install
	@make -s clear-folder
	@make -s env
	@echo "Laravel installation complete"

laravel-init: up
	@make -s init
	@make -s clean
	@echo "Laravel installation complete"

init: prepare-app prepare-db

prepare-db: migrate db-seed

prepare-app: composer-install env key-generate #cert-generate
	@echo -e "Make: App is completed. \n"

install:
	@echo -e "Make: Installing Laravel...\n"
	@docker exec -it "${COMPOSE_PROJECT_NAME}_app"  sh -c "composer create-project --prefer-dist laravel/laravel ./laravel"

clear-folder:
	@echo -e "Make: Clearing installation folder...\n"
	@docker exec -it "${COMPOSE_PROJECT_NAME}_app"  sh -c "mv ./laravel/* ./ && rm -rf ./laravel"

clean:
	@docker system prune --volumes --force

up:
	@echo -e "Make: Up containers.\n"
	@docker-compose -f docker-compose.yml -p $project_name up -d --force-recreate
	@echo -e "Make: Visit https://${VIRTUAL_HOST} .\n"

down:
	@docker-compose -f docker-compose.yml -p $project_name down

start:
	@docker-compose -f docker-compose.yml -p $project_name start

migrate:
	@echo -e "Make: Database migration.\n"
	@docker-compose -f docker-compose.yml -p $project_name run app php artisan migrate --force

db-seed:
	@echo -e "Make: Database seeding.\n"
	@docker-compose -f docker-compose.yml -p $project_name run app php artisan db:seed --force

db-fresh:
	@echo -e "Make: Fresh database.\n"
	@docker exec -it "${COMPOSE_PROJECT_NAME}_app" sh -c "php artisan migrate:fresh --seed --force"

logs:
	@docker-compose -f docker-compose.yml -p $project_name logs --follow

stop:
	@docker-compose -f docker-compose.yml -p $project_name stop

build:
	@docker-compose -f docker-compose.yml -p $project_name build

composer-install:
	@echo -e "Make: Installing composer dependencies.\n"
	@docker exec -it "${COMPOSE_PROJECT_NAME}_app" sh -c "composer install"

composer-update:
	@echo -e "Make: Installing composer dependencies.\n"
	@docker exec -it "${COMPOSE_PROJECT_NAME}_app" sh -c "composer update"

env:
	@echo -e "Make: Сopying env file.\n"
	cp ./docker/example/.env.example ./.env

key-generate:
	@echo -e "Make: Generate Laravel key.\n"
	@docker exec -it "${COMPOSE_PROJECT_NAME}_app" sh -c "php artisan key:generate"

#cert-generate:
#	@echo -e "Make: Generate self-sign certifications.\n"
#	@mkcert ${VIRTUAL_HOST}
#	@mv ./${VIRTUAL_HOST}.pem ./storage/certs/${VIRTUAL_HOST}.crt
#	@mv ./${VIRTUAL_HOST}-key.pem ./storage/certs/${VIRTUAL_HOST}.key

helper-generate:
	@docker exec -it "${COMPOSE_PROJECT_NAME}_app" sh -c "php artisan ide-helper:eloquent && php artisan ide-helper:generate && php artisan ide-helper:meta && php artisan ide-helper:models"

bash:
	@docker exec -it "${COMPOSE_PROJECT_NAME}_app" bash

bash-node:
	@docker exec -it "${COMPOSE_PROJECT_NAME}_node" bash

perm:
	sudo chgrp -R www-data storage bootstrap/cache
	sudo chmod -R ug+rwx storage bootstrap/cache

assets-install:
	@docker-compose exec "$(NODE_CONTAINER_NAME)" yarn install

assets-rebuild:
	@docker exec -it "${COMPOSE_PROJECT_NAME}_node" sh -c "npm rebuild node-sass --force"

assets-dev:
	@docker exec -it "${COMPOSE_PROJECT_NAME}_node" sh -c "yarn run dev"

assets-watch:
	@docker-compose exec "$(NODE_CONTAINER_NAME)" yarn run watch
