SHELL=/bin/bash -e

.DEFAULT_GOAL := help

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

include .env
export $(shell sed 's/=.*//' .env)

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
BASE_NAME_DIR := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))
NAME_SERVICE_IN_ENV_FILE := $(grep BASE_NAME_SERVICE .env | cut -d '=' -f2)
CURRENT_USER = $(shell id -u):$(shell id -g)
RUN_APP_ARGS = -it --user "$(CURRENT_USER)"

ifeq ($(BASE_NAME_SERVICE),"_")
	BASE_NAME_SERVICE := $(BASE_NAME_DIR)
endif

export BASE_NAME_SERVICE

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

up: memory ## Разветрывание контейнеров приложения
	@echo -e "Make: Up containers.\n"
	CURRENT_USER=${CURRENT_USER} COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME} docker-compose -f docker-compose.yml -p $project_name up -d --force-recreate
	@echo -e "Make: Visit https://${VIRTUAL_HOST} .\n"

down: ## Выключение контейнеров приложения
	@docker-compose -f docker-compose.yml -p $project_name down

start:
	@docker-compose -f docker-compose.yml -p $project_name start

restart: down up ## Рестарт контейнеров

laravel-install: ## Установка laravel
	@echo -e "Make: Installing Laravel instance...\n"
	@make -s build
	@make -s install
	@make -s clear-folder
	@make -s env
	@echo "Laravel installation complete"

laravel-init: up ## Инициализация приложения
	@make -s init
	@make -s clean
	@echo "Laravel installation complete"

init: prepare-app prepare-db

prepare-db: migrate db-seed

prepare-app: composer-install env key-generate #cert-generate
	@echo -e "Make: App is completed. \n"

install:
	@echo -e "Make: Installing Laravel...\n"
	@docker exec ${RUN_APP_ARGS} "${COMPOSE_PROJECT_NAME}_app_1"  sh -c "composer create-project --prefer-dist laravel/laravel ./laravel"

clear-folder:
	@echo -e "Make: Clearing installation folder...\n"
	@docker exec ${RUN_APP_ARGS} "${COMPOSE_PROJECT_NAME}_app_1"  sh -c "mv ./laravel/* ./ && rm -rf ./laravel"

clean:
	@docker system prune --volumes --force

migrate:
	@echo -e "Make: Database migration.\n"
	@docker-compose -f docker-compose.yml -p $project_name run app php artisan migrate --force

tinker:
	@docker-compose -f docker-compose.yml -p $project_name run app php artisan tinker

db-seed:
	@echo -e "Make: Database seeding.\n"
	@docker-compose -f docker-compose.yml -p $project_name run app php artisan db:seed --force

db-fresh:
	@echo -e "Make: Fresh database.\n"
	@docker exec ${RUN_APP_ARGS} "${COMPOSE_PROJECT_NAME}_app_1" sh -c "php artisan migrate:fresh --seed --force"

logs:
	@docker-compose -f docker-compose.yml -p $project_name logs --follow

stop:
	@docker-compose -f docker-compose.yml -p $project_name stop

composer-install:
	@echo -e "Make: Installing composer dependencies.\n"
	@docker exec ${RUN_APP_ARGS} "${COMPOSE_PROJECT_NAME}_app_1" sh -c "composer install"

composer-update:
	@echo -e "Make: Installing composer dependencies.\n"
	@docker exec ${RUN_APP_ARGS} "${COMPOSE_PROJECT_NAME}_app_1" sh -c "composer update"

env:
	@echo -e "Make: Сopying env file.\n"
	@docker exec ${RUN_APP_ARGS} "${COMPOSE_PROJECT_NAME}_app_1" sh -c "test -f ./.env || cp ./docker/example/.env.example ./.env"

key-generate:
	@echo -e "Make: Generate Laravel key.\n"
	@docker exec ${RUN_APP_ARGS} "${COMPOSE_PROJECT_NAME}_app_1" sh -c "php artisan key:generate"

#cert-generate:
#	@echo -e "Make: Generate self-sign certifications.\n"
#	@mkcert ${VIRTUAL_HOST}
#	@mv ./${VIRTUAL_HOST}.pem ./storage/certs/${VIRTUAL_HOST}.crt
#	@mv ./${VIRTUAL_HOST}-key.pem ./storage/certs/${VIRTUAL_HOST}.key

helper-generate:
	@docker exec ${RUN_APP_ARGS} "${COMPOSE_PROJECT_NAME}_app_1" sh -c "php artisan ide-helper:eloquent && php artisan ide-helper:generate && php artisan ide-helper:meta && php artisan ide-helper:models"

apidoc-generate:
	@echo -e "Make: Generate docs for api.\n"
	@docker exec ${RUN_APP_ARGS} "${COMPOSE_PROJECT_NAME}_app_1" sh -c "php artisan apidoc:generate"

bash: ## Доступ к консоли приложения
	@docker exec ${RUN_APP_ARGS} "${COMPOSE_PROJECT_NAME}_app_1" bash

bash-node: ## Доступ к консоли контейнера node
	@docker exec ${RUN_APP_ARGS} "${COMPOSE_PROJECT_NAME}_node_1" bash

perm: ## Настройка доступов
	sudo chgrp -R www-data storage bootstrap/cache
	sudo chmod -R ug+rwx storage bootstrap/cache

test: ## Запуск тестов
	@docker exec ${RUN_APP_ARGS} "${COMPOSE_PROJECT_NAME}_app_1" sh -c "./vendor/phpunit/phpunit/phpunit"

horizon:
	@docker exec ${RUN_APP_ARGS} "${COMPOSE_PROJECT_NAME}_app_1" sh -c "php artisan horizon"

assets-install: ## Установка yarn
	@docker exec ${RUN_APP_ARGS} "${COMPOSE_PROJECT_NAME}_node_1" sh -c "yarn install"

assets-rebuild:
	@docker exec ${RUN_APP_ARGS} "${COMPOSE_PROJECT_NAME}_node_1" sh -c "npm rebuild node-sass --force"

assets-dev:
	@docker exec ${RUN_APP_ARGS} "${COMPOSE_PROJECT_NAME}_node_1" sh -c "yarn run dev"

assets-watch:
	@docker exec ${RUN_APP_ARGS} "${COMPOSE_PROJECT_NAME}_node_1" sh -c "yarn run watch"

memory:
	sudo sysctl -w vm.max_map_count=262144