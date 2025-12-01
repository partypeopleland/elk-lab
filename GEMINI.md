# ELK Stack with Docker Compose

## Communication Guidelines

- **Language**: Please use Traditional Chinese (zh-tw) for all documentation, communication, and conversation.
- **Terminology**: Professional and technical terms should remain in English.

## Project Overview

This project provides a complete ELK (Elasticsearch, Logstash, Kibana) stack environment using Docker Compose. It also includes Metricbeat for monitoring the stack and the host system.

The core of this project is its automated setup process. A special `setup` container runs on the first launch to generate all necessary TLS certificates and configure passwords. Subsequent launches are faster as they skip this setup and directly start the main services.

**Key Technologies:**
- Elasticsearch
- Logstash
- Kibana
- Metricbeat
- Docker Compose

**Architecture:**
- `docker-compose.yml`: Defines the main services: `es01`, `kibana`, `logstash`, and `metricbeat`.
- `docker-compose.setup.yml`: Contains the one-time `setup` service for initialization.
- `start.sh`: The main entry script that intelligently chooses between initial setup and normal startup.
- `.env`: Manages environment-specific configurations like stack version, ports, and credentials.
- `logstash/`: Contains Logstash pipeline configurations.
- `metricbeat/`: Contains Metricbeat module configurations.
- `certs/`: Stores the generated TLS certificates.
- `esdata/`: Persists Elasticsearch data.

## Building and Running

The primary way to interact with this project is through the `start.sh` script.

**To start the stack (for the first time or subsequent runs):**
```bash
./start.sh
```
This script will:
1.  Detect if certificates exist in the `./certs` directory.
2.  If not, it runs a one-time setup using `docker-compose -f docker-compose.yml -f docker-compose.setup.yml up -d` to generate certificates and passwords.
3.  If certificates exist, it starts the services normally using `docker compose up -d`.

**To stop the stack:**
```bash
# To stop services and remove containers (recommended)
docker compose down

# To only stop the services without removing containers
docker compose stop
```

**To view logs:**
```bash
# View logs for all services
docker compose logs -f

# View logs for a specific service (e.g., logstash)
docker compose logs -f logstash
```

## Development Conventions

- **Configuration:** All service configurations are managed through their respective files (e.g., `logstash/logstash.yml`, `metricbeat/metricbeat.yml`). Environment variables for versions, ports, and passwords are set in the `.env` file.
- **Logstash Pipelines:** New Logstash pipeline configurations (`.conf` files) should be added to the `logstash/conf.d/` directory. The main pipeline configuration is defined in `logstash/pipelines.yml`.
- **Passwords:** Default passwords are set in the `.env` file. It is crucial to change `ELASTIC_PASSWORD` and `KIBANA_PASSWORD` from the default `changeme` value for any real deployment.
- **Certificate Management:** The initial certificate generation is handled automatically. For deploying with custom, production-ready certificates, follow the detailed instructions in the `README.md` file under the "正式環境部署 (使用自有憑證)" section. This involves replacing the auto-generated files in the `certs/` directory and adjusting file permissions.
