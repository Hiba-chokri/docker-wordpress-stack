#!/bin/sh

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

mysqld --user=mysql &
pid=$!

while ! mysqladmin ping --silent; do
    sleep 1
done

if [ ! -f /var/lib/mysql/.init_done ]; then
    mysql -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
    touch /var/lib/mysql/.init_done
fi

mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
wait $pid

exec mysqld --user=mysql
