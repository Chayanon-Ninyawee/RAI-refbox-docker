# RCLL Portable RefBox

A portable Docker Compose setup for running the RoboCup Logistics League (RCLL) RefBox and its supporting services. Designed to run on Linux and Windows through WSL 2 with Docker support.

## Architecture

The stack runs the following services:

| Service | Purpose |
|---|---|
| RefBox | RCLL referee box |
| MongoDB | Persistent database for RefBox |
| RefBox Frontend | Web interface for RefBox |
| MQTT Broker | MQTT message broker |
| MQTT Bridge | Connects RefBox communication to MQTT |

The robot or robot emulator runs separately and communicates with RefBox over the network, as it would in a real deployment.

## Requirements

- Docker Engine or Docker Desktop
- Docker Compose v2
- Bash
- Git (optional)

For Windows, use WSL 2 with Docker Desktop integration or another Docker Engine accessible from WSL.

## Project Structure

```text
rcll-portable/
├── .env.example
├── .gitignore
├── docker-compose.yml
├── README.md
├── scripts/
│   └── run.sh
├── config/
│   ├── mosquitto/
│   │   └── mosquitto.conf
│   └── refbox/
│       ├── challenges/
│       ├── comm/
│       └── ...
├── data/
│   └── mongodb/
├── logs/
│   ├── refbox/
│   └── mqtt/
└── backups/
```

Runtime directories such as `data/`, `logs/`, and `backups/` are local and should not be committed to Git.

## Initial Setup

### 1. Get the project

```bash
git clone <repository-url> rcll-portable
cd rcll-portable
```

If you already have the project directory, enter it instead.

### 2. Configure environment variables

The first setup command creates `.env` from `.env.example` if `.env` does not exist.

```bash
./scripts/run.sh setup
```

Review `.env` and configure the values for your network and MQTT bridge.

Do not commit `.env`. It may contain local settings or credentials.

### 3. Configure RefBox

Place the required RefBox configuration files under `config/refbox/`.

The Compose setup expects the challenge and communication configuration at:

```text
config/refbox/challenges/thopen/nav_hard.yaml
config/refbox/comm/raikmitl_comm.yaml
```

Check the communication configuration before starting RefBox:

- Set peer addresses and ports for your deployment.
- Ensure the public and private UDP communication settings match the robot configuration.
- Check MongoDB settings. When MongoDB is accessed through the Compose network, its hostname should match the MongoDB service name.
- Confirm the configured challenge file exists.

Do not copy machine-specific IP addresses from another environment without checking whether they apply to the current network.

### 4. Validate and start

```bash
./scripts/run.sh config
./scripts/run.sh pull
./scripts/run.sh up
```

Check service status:

```bash
./scripts/run.sh status
```

## Accessing the RefBox

The frontend is configured to use host port `8080`.

Open:

```text
http://localhost:8080
```

When accessing it from another computer, replace `localhost` with the LAN IP address of the computer running RefBox:

```text
http://<REFBOX-LAN-IP>:8080
```

The computer's firewall must allow the required connections.

## Network Configuration

### Running RefBox and the robot on separate computers

This is the intended deployment model.

1. Start RefBox on the RefBox computer.
1. Start the robot or robot emulator on another computer.
1. Connect both computers to a network that permits communication between them.
1. Configure RefBox and the robot with the correct peer IP addresses and UDP ports.
1. Verify that the relevant TCP and UDP traffic is permitted by the host firewalls.

The RefBox communication configuration must use addresses reachable from the robot computer. Do not use Docker-internal addresses such as a container's private bridge IP as though they were LAN addresses.

The robot emulator's Compose file is maintained separately in the robot project. Its port mappings must not conflict with other processes on the emulator computer.

### Running both on one computer

The default setup is intended for the separate-computer deployment. Running both stacks on the same host requires an additional networking configuration to avoid host UDP port conflicts. Do not assume that both default Compose files can publish the same ports simultaneously.

## Commands

Run commands from the project directory.

| Command | Description |
|---|---|
| `./scripts/run.sh setup` | Check prerequisites and create runtime directories |
| `./scripts/run.sh config` | Validate the Compose configuration |
| `./scripts/run.sh pull` | Pull container images |
| `./scripts/run.sh up` | Start all services |
| `./scripts/run.sh down` | Stop services without removing persistent volumes |
| `./scripts/run.sh restart` | Restart services |
| `./scripts/run.sh status` | Show service status |
| `./scripts/run.sh logs` | Follow logs from all services |
| `./scripts/run.sh logs-refbox` | Follow RefBox logs |
| `./scripts/run.sh logs-mqtt` | Follow MQTT broker logs |
| `./scripts/run.sh logs-bridge` | Follow MQTT bridge logs |
| `./scripts/run.sh backup` | Back up configuration and, when running, MongoDB data |
| `./scripts/run.sh help` | Display available commands |

Follow logs with `Ctrl+C` to stop viewing them. This does not stop the containers.

## Troubleshooting

### A port is already allocated

Check which process or container is using the port.

```bash
docker ps
sudo ss -lntup
```

Resolve the port conflict or adjust the deployment's network configuration. Do not blindly remove port mappings, because the robot and RefBox may depend on them.

### A service is not running

```bash
./scripts/run.sh status
./scripts/run.sh logs
```

To inspect a specific service:

```bash
docker compose logs --tail=100 refbox
docker compose logs --tail=100 mongodb
docker compose logs --tail=100 refbox-frontend
docker compose logs --tail=100 mqtt-broker
docker compose logs --tail=100 mqtt-bridge
```

### The robot cannot communicate with RefBox

Check:

- Both computers can reach each other over the network.
- The configured peer IP addresses are correct.
- UDP ports match the RefBox communication configuration.
- The host firewalls allow the required traffic.
- The robot is using the correct team and communication settings.
- The RefBox and robot logs show no connection or configuration errors.

### MongoDB is unavailable

Check the MongoDB container and RefBox logs:

```bash
./scripts/run.sh status
docker compose logs --tail=100 mongodb
docker compose logs --tail=100 refbox
```

Ensure the RefBox database configuration uses the correct hostname for the chosen deployment.

## Backups

Run:

```bash
./scripts/run.sh backup
```

Backups are saved under `backups/`.

When MongoDB is running, the script creates a MongoDB logical dump and archives it with the configuration. If MongoDB is stopped, the backup contains configuration only.

Keep backups in a secure location. They may contain environment settings or other sensitive information.

## Stopping the Stack

```bash
./scripts/run.sh down
```

This stops the Compose services without deleting the persistent database directory or named volumes. Do not manually delete `data/` if you need to preserve database contents.

## Git

The `.gitignore` excludes local environment settings and runtime data. The following should normally remain tracked:

- `docker-compose.yml`
- `.env.example`
- `README.md`
- `scripts/`
- `config/`, excluding any secrets or machine-specific private configuration

Review configuration files before committing them to ensure they do not contain credentials or private network details.
