prd-build:
	docker-compose -f docker-compose.yml build
prd-up:
	docker-compose -f docker-compose.yml up

dev-build:
	docker-compose -f docker-compose.yml -f docker-compose-dev.yml build
dev-up:
	docker-compose -f docker-compose.yml -f docker-compose-dev.yml up