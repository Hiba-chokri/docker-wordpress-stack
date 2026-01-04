# Inception Infrastructure Setup Guide

## Domain Name Resolution

Before accessing the WordPress site, you need to configure your local machine to resolve the domain name.

### Configure /etc/hosts

Add the following entry to your `/etc/hosts` file:

```
127.0.0.1    hichokri.42.fr
```

To add this entry, run:

```bash
sudo sh -c 'echo "127.0.0.1    hichokri.42.fr" >> /etc/hosts'
```

Or manually edit the file:

```bash
sudo nano /etc/hosts
```

And add the line:
```
127.0.0.1    hichokri.42.fr
```

### Verify Configuration

After adding the entry, verify it works:

```bash
ping hichokri.42.fr
```

You should see responses from `127.0.0.1`.

## Environment Variables

The `.env` file contains all configuration variables:

| Variable | Description |
|----------|-------------|
| DOMAIN_NAME | Website domain (hichokri.42.fr) |
| MYSQL_DATABASE | WordPress database name |
| MYSQL_USER | Database user for WordPress |
| MYSQL_PASSWORD | Database user password |
| MYSQL_ROOT_PASSWORD | MariaDB root password |
| WP_ADMIN_USER | WordPress admin username |
| WP_ADMIN_PASSWORD | WordPress admin password |
| WP_ADMIN_EMAIL | WordPress admin email |

**Important**: The WordPress admin username (`WP_ADMIN_USER`) must NOT contain:
- "admin"
- "Admin"
- "administrator"
- "Administrator"

The default value `wpmanager` is compliant with this requirement.

## Starting the Infrastructure

1. Build and start all containers:
   ```bash
   make all
   ```

2. Access WordPress at: https://hichokri.42.fr

3. Accept the self-signed certificate warning in your browser.

## Verifying WordPress Installation

After starting the infrastructure, verify the installation:

1. **Check containers are running**:
   ```bash
   docker ps
   ```
   You should see nginx, wordpress, and mariadb containers running.

2. **Test NGINX responds on port 443**:
   ```bash
   curl -k https://hichokri.42.fr
   ```

3. **Verify database connection**:
   ```bash
   docker exec wordpress wp db check --path=/var/www/html --allow-root
   ```

4. **Check WordPress installation status**:
   ```bash
   docker exec wordpress wp core is-installed --path=/var/www/html --allow-root && echo "WordPress is installed"
   ```

5. **List WordPress users** (verify admin username is compliant):
   ```bash
   docker exec wordpress wp user list --path=/var/www/html --allow-root
   ```

## Stopping the Infrastructure

```bash
make down
```

## Cleaning Up

Remove containers and volumes:
```bash
make clean
```

Full cleanup including data directories:
```bash
make fclean
```
