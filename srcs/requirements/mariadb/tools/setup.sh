#!/bin/bash
set -e

# Validate that admin username doesn't contain forbidden patterns
validate_username() {
    local username="$1"
    if echo "$username" | grep -qiE "(admin|administrator)"; then
        echo "Error: Username cannot contain 'admin' or 'administrator'"
        exit 1
    fi
}

# Validate MYSQL_USER if set
if [ -n "$MYSQL_USER" ]; then
    validate_username "$MYSQL_USER"
fi

# Check if database is already initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    echo "Starting MariaDB temporarily for setup..."
    mysqld --user=mysql --skip-networking &
    pid="$!"

    # Wait for MariaDB to be ready
    for i in {1..30}; do
        if mysqladmin ping --silent 2>/dev/null; then
            break
        fi
        echo "Waiting for MariaDB to start... ($i/30)"
        sleep 1
    done

    if ! mysqladmin ping --silent 2>/dev/null; then
        echo "Error: MariaDB failed to start"
        exit 1
    fi

    echo "Creating database and users..."
    mysql -u root <<-EOSQL
        -- Set root password
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        
        -- Create database
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        
        -- Create application user
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        
        -- Flush privileges
        FLUSH PRIVILEGES;
EOSQL

    echo "Shutting down temporary MariaDB instance..."
    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

    # Wait for shutdown
    wait "$pid"
    echo "MariaDB initialization complete."
fi

echo "Starting MariaDB..."
exec "$@"
