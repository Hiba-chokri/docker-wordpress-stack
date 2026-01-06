# Developer Documentation

## Environment Setup

### Prerequisites

1. **Virtual Machine** with Linux (Debian/Ubuntu recommended)
2. **Docker** installed:
   ```bash
   sudo apt-get update
   sudo apt-get install docker.io docker-compose
   ```
3. **Make** utility:
   ```bash
   sudo apt-get install make
   ```

### Configuration Files

#### Environment Variables (srcs/.env)

```
DOMAIN_NAME=hichokri.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=hiba
MYSQL_PASSWORD=<password>
MYSQL_ROOT_PASSWORD=<password>
WP_ADMIN_USER=hiba
WP_ADMIN_PASSWORD=<password>
WP_ADMIN_EMAIL=hichokri@student.42.fr
WP_USER=editor
WP_USER_EMAIL=editor@hichokri.42.fr
WP_USER_PASS=<password>
```

#### Domain Configuration

Add to `/etc/hosts`:
```
127.0.0.1 hichokri.42.fr
```

## Building and Launching

### Build Images

```bash
make build
```

This creates data directories and builds all Docker images.

### Start Containers

```bash
make up
```

Starts containers in detached mode.

### Full Build and Start

```bash
make
```

Runs both build and up targets.

## Container Management

### List Running Containers

```bash
docker ps
```

### View Container Logs

```bash
docker logs <container_name>
docker logs -f <container_name>  # Follow logs
```

### Execute Commands in Container

```bash
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash
```

### Restart a Container

```bash
docker restart nginx
docker restart wordpress
docker restart mariadb
```

## Volume Management

### List Volumes

```bash
docker volume ls
```

### Inspect Volume

```bash
docker volume inspect srcs_wordpress_data
docker volume inspect srcs_mariadb_data
```

### Remove Volumes

```bash
docker volume rm srcs_wordpress_data srcs_mariadb_data
```

Or use:
```bash
make clean
```

## Data Storage

### Volume Locations

Data is stored in `/home/hichokri/data/`:

| Volume | Host Path | Container Path |
|--------|-----------|----------------|
| wordpress_data | /home/hichokri/data/wordpress | /var/www/html |
| mariadb_data | /home/hichokri/data/mariadb | /var/lib/mysql |

### Data Persistence

- Data persists across container restarts
- Data is removed with `make fclean`
- Volumes are Docker named volumes (not bind mounts)

## Project Structure

```
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   └── conf/
        │       └── nginx.conf
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── www.conf
        │   └── tools/
        │       └── setup.sh
        └── mariadb/
            ├── Dockerfile
            ├── .dockerignore
            ├── conf/
            │   └── 50-server.cnf
            └── tools/
                └── setup.sh
```

## Makefile Targets

| Target | Description |
|--------|-------------|
| all | Default: build + up |
| build | Create directories, build images |
| up | Start containers |
| down | Stop containers |
| clean | Remove containers, volumes, images |
| fclean | clean + remove host data |
| re | fclean + all |

## Debugging

### Check Docker Network

```bash
docker network ls
docker network inspect srcs_inception
```

### Test Database Connection

```bash
docker exec wordpress mysqladmin ping -h mariadb
```

### Check WordPress Installation

```bash
docker exec wordpress wp core is-installed --allow-root --path=/var/www/html
docker exec wordpress wp user list --allow-root --path=/var/www/html
```

### Rebuild Single Service

```bash
docker-compose -f srcs/docker-compose.yml build nginx
docker-compose -f srcs/docker-compose.yml up -d nginx
```
