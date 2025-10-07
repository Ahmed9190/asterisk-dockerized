.PHONY: help start stop restart logs build clean backup test

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

start: ## Start all services
	docker compose up -d

stop: ## Stop all services
	docker compose down

restart: ## Restart all services
	docker compose restart

logs: ## View logs (follow mode)
	docker compose logs -f

build: ## Build images
	docker compose build

clean: ## Remove all containers and volumes
	docker compose down -v

backup: ## Backup configurations
	tar -czf backup-$$(date +%Y%m%d-%H%M%S).tar.gz configs/ certs/ coturn/

test: ## Run basic tests
	@echo "Testing Asterisk..."
	docker compose exec asterisk asterisk -rx "core show version"
	@echo "\nTesting PJSIP..."
	docker compose exec asterisk asterisk -rx "pjsip show endpoints"
	@echo "\nTesting Coturn..."
	docker compose logs coturn | grep "listener opened" | head -4

status: ## Show service status
	docker compose ps

cli: ## Open Asterisk CLI
	docker compose exec asterisk asterisk -rvvv

shell-asterisk: ## Shell into Asterisk container
	docker compose exec asterisk bash

shell-coturn: ## Shell into Coturn container
	docker compose exec coturn sh

prod-start: ## Start production services
	docker compose -f docker-compose.prod.yml up -d

prod-stop: ## Stop production services
	docker compose -f docker-compose.prod.yml down

