# User Documentation

## Services Overview

This infrastructure provides a complete WordPress website with:

| Service | Description | Port |
|---------|-------------|------|
| NGINX | Web server and reverse proxy | 443 (HTTPS) |
| WordPress | Content management system | Internal |
| MariaDB | Database server | Internal |

## Starting and Stopping

### Start the Project

```bash
make
```

This builds all Docker images and starts the containers.

### Stop the Project

```bash
make down
```

This stops all running containers.

### Full Restart

```bash
make re
```

This removes everything and rebuilds from scratch.

## Accessing the Website

### Website URL

Open your browser and go to:
```
https://hichokri.42.fr
```

Note: You may see a certificate warning because the TLS certificate is self-signed. Click "Advanced" and proceed to the site.

### Administration Panel

Access the WordPress admin panel at:
```
https://hichokri.42.fr/wp-admin
```

## Credentials

### WordPress Admin

- **Username**: hiba
- **Password**: (see .env file)

### WordPress Regular User

- **Username**: editor
- **Password**: (see .env file)

### Database

Credentials are stored in `srcs/.env` file:
- `MYSQL_USER`: Database username
- `MYSQL_PASSWORD`: Database password
- `MYSQL_ROOT_PASSWORD`: Root password

## Managing Credentials

1. Open `srcs/.env` file
2. Modify the password values
3. Rebuild the project: `make re`

**Important**: Never commit the `.env` file to Git.

## Checking Services

### Verify Containers are Running

```bash
docker ps
```

You should see three containers: nginx, wordpress, mariadb

### Check Container Logs

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Test NGINX

The website should be accessible at `https://hichokri.42.fr`

### Test Database Connection

```bash
docker exec mariadb mysqladmin ping -u root -p
```

## Troubleshooting

### Website Not Loading

1. Check if containers are running: `docker ps`
2. Check NGINX logs: `docker logs nginx`
3. Verify `/etc/hosts` has the domain entry

### Database Connection Error

1. Check MariaDB logs: `docker logs mariadb`
2. Verify credentials in `.env` match
3. Restart containers: `make down && make up`

### Permission Issues

Run cleanup with sudo:
```bash
make fclean
make
```
