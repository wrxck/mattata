prd-up:
    docker-compose -f docker-compose.yml -up

dev-up:
    docker-compose -f docker-compose.yml -f docker-compose-dev.yml up