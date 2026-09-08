*This project has been created as part of the 42 curriculum by hichokri.*

# docker-wordpress-stack

## Description

Inception is a Docker-based infrastructure project that sets up a small web hosting environment. The project demonstrates system administration skills using Docker containerization to deploy a complete WordPress website with NGINX reverse proxy and MariaDB database.

### Goal

Create a multi-container Docker infrastructure with:
- NGINX as secure entry point (TLS only)
- WordPress with PHP-FPM for content management
- MariaDB for database storage

### Project Overview

The infrastructure uses three isolated containers communicating through a Docker network, with persistent data storage using named volumes.

## Instructions

### Prerequisites

- Docker and Docker Compose installed
- Virtual Machine environment
- Make utility

### Installation

1. Clone the repository
2. Configure `/etc/hosts`:
   ```
   127.0.0.1 hichokri.42.fr
   ```
3. Build and run:
   ```bash
   make
   ```

### Commands

| Command | Description |
|---------|-------------|
| `make` | Build and start all containers |
| `make build` | Build Docker images |
| `make up` | Start containers |
| `make down` | Stop containers |
| `make clean` | Remove containers, volumes, images |
| `make fclean` | Full clean including data |
| `make re` | Rebuild from scratch |

## Resources

### Documentation

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Documentation](https://developer.wordpress.org/)
- [MariaDB Documentation](https://mariadb.com/kb/en/)

### AI Usage

AI was used to assist with:
- Generating boilerplate configuration files
- Debugging Docker networking issues
- Writing documentation

All AI-generated content was reviewed, tested, and validated manually.

## Project Description

### Docker Usage

This project uses Docker to containerize three services:
- **NGINX**: Reverse proxy with TLS termination
- **WordPress**: PHP application with php-fpm
- **MariaDB**: Relational database

Each service runs in its own isolated container, built from custom Dockerfiles using Debian Bullseye as the base image.

### Design Choices

- **Debian Bullseye**: Chosen for stability and package availability
- **TLSv1.2/1.3**: Modern secure protocols only
- **Named volumes**: For data persistence
- **Bridge network**: For container isolation

### Comparisons

#### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker |
|--------|-----------------|--------|
| Isolation | Full OS isolation | Process-level isolation |
| Resources | Heavy (full OS) | Lightweight (shared kernel) |
| Startup | Minutes | Seconds |
| Portability | Limited | High |

Docker is preferred here for its lightweight nature and fast deployment.

#### Secrets vs Environment Variables

| Aspect | Secrets | Environment Variables |
|--------|---------|----------------------|
| Security | More secure (encrypted) | Less secure (plain text) |
| Access | File-based in container | Available to all processes |
| Complexity | More setup required | Simple to use |

This project uses environment variables via `.env` file for simplicity.

#### Docker Network vs Host Network

| Aspect | Docker Network | Host Network |
|--------|---------------|--------------|
| Isolation | Containers isolated | No isolation |
| Port conflicts | None | Possible |
| Security | Better | Less secure |

Docker bridge network is used for container isolation and security.

#### Docker Volumes vs Bind Mounts

| Aspect | Named Volumes | Bind Mounts |
|--------|--------------|-------------|
| Management | Docker managed | User managed |
| Portability | More portable | Host-dependent |
| Performance | Optimized | Direct access |

Named volumes are used as required by the subject, with data stored in `/home/hichokri/data`.
