#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

COMPOSE=(docker compose -f "$ROOT/docker-compose.yml")

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

check_docker() {
    command -v docker >/dev/null 2>&1 ||
        die "Docker is not installed."

    docker compose version >/dev/null 2>&1 ||
        die "Docker Compose v2 is required."

    docker info >/dev/null 2>&1 ||
        die "Docker is not running or permission was denied."
}

check_files() {
    [[ -f "$ROOT/docker-compose.yml" ]] ||
        die "Missing docker-compose.yml"

    if [[ ! -f "$ROOT/.env" ]]; then
        [[ -f "$ROOT/.env.example" ]] ||
            die "Missing both .env and .env.example"

        cp "$ROOT/.env.example" "$ROOT/.env"
        printf 'Created .env from .env.example. Review it before starting.\n'
    fi
}

setup() {
    check_docker
    check_files

    mkdir -p \
        "$ROOT/data/mongodb" \
        "$ROOT/logs/refbox" \
        "$ROOT/logs/mqtt" \
        "$ROOT/backups"

    printf 'Setup complete. Review .env and config/refbox/ before starting.\n'
}

validate_config() {
    check_docker
    check_files
    "${COMPOSE[@]}" config --quiet
    printf 'Compose configuration is valid.\n'
}

backup() {
    check_docker
    check_files

    local timestamp destination dump
    timestamp="$(date +%Y%m%d-%H%M%S)"
    destination="$ROOT/backups/rcll-portable-${timestamp}.tar.gz"
    dump="$ROOT/backups/mongodb-${timestamp}.archive.gz"

    mkdir -p "$ROOT/backups"

    if "${COMPOSE[@]}" ps --status running --services | grep -qx mongodb; then
        "${COMPOSE[@]}" exec -T mongodb mongodump --archive --gzip > "$dump"

        tar -czf "$destination" \
            -C "$ROOT" .env docker-compose.yml config \
            -C "$ROOT" "backups/$(basename "$dump")"

        rm -f "$dump"
    else
        printf 'MongoDB is not running; creating a configuration-only backup.\n'
        tar -czf "$destination" \
            -C "$ROOT" .env docker-compose.yml config
    fi

    printf 'Backup saved: %s\n' "$destination"
}

usage() {
    cat <<'EOF'
Usage: ./scripts/run.sh COMMAND

Setup:
  setup          Check prerequisites and create directories
  config         Validate Compose configuration
  pull           Pull container images

Lifecycle:
  up             Start all services
  down           Stop services without deleting persistent data
  restart        Restart services
  status         Show service status

Logs:
  logs           Follow all service logs
  logs-refbox    Follow RefBox logs
  logs-mqtt      Follow MQTT broker logs
  logs-bridge    Follow MQTT bridge logs

Maintenance:
  backup         Back up configuration and MongoDB data
  help           Show this help
EOF
}

command="${1:-help}"

case "$command" in
    setup)
        setup
        ;;
    config)
        validate_config
        ;;
    pull)
        check_docker
        check_files
        "${COMPOSE[@]}" pull
        ;;
    up)
        check_docker
        check_files
        mkdir -p "$ROOT/data/mongodb" "$ROOT/logs/refbox" "$ROOT/logs/mqtt" "$ROOT/backups"
        validate_config
        "${COMPOSE[@]}" up -d
        "${COMPOSE[@]}" ps
        ;;
    down)
        check_docker
        "${COMPOSE[@]}" down
        ;;
    restart)
        check_docker
        "${COMPOSE[@]}" restart
        ;;
    status|ps)
        check_docker
        "${COMPOSE[@]}" ps
        ;;
    logs)
        check_docker
        "${COMPOSE[@]}" logs -f --tail=100
        ;;
    logs-refbox)
        check_docker
        "${COMPOSE[@]}" logs -f --tail=100 refbox
        ;;
    logs-mqtt)
        check_docker
        "${COMPOSE[@]}" logs -f --tail=100 mqtt-broker
        ;;
    logs-bridge)
        check_docker
        "${COMPOSE[@]}" logs -f --tail=100 mqtt-bridge
        ;;
    backup)
        backup
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        usage
        die "Unknown command: $command"
        ;;
esac

