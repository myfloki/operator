set shell := ["bash", "-c"]

DOCKER_COMPOSE := if `docker compose version &> /dev/null` == "0" { "docker compose" } else { "docker-compose" }

# Onboard a new operator
setup:
    ./setup.sh

# Start the operator services
up:
    {{DOCKER_COMPOSE}} up -d

# Stop the operator services
down:
    {{DOCKER_COMPOSE}} down

# Restart the operator services
restart:
    {{DOCKER_COMPOSE}} restart

# View logs
logs:
    {{DOCKER_COMPOSE}} logs -f

# View logs for peer
logs-peer:
    {{DOCKER_COMPOSE}} logs -f flokicoin-peer

# View logs for electrum
logs-electrum:
    {{DOCKER_COMPOSE}} logs -f electrum

# Show status
status:
    {{DOCKER_COMPOSE}} ps
