FROM debian:bullseye

# Install MariaDB server
RUN apt-get update && apt-get install -y \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copy setup script
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# Create necessary directories and set permissions
RUN mkdir -p /var/run/mysqld \
    && chown -R mysql:mysql /var/run/mysqld \
    && chmod 755 /var/run/mysqld

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/setup.sh"]
CMD ["mysqld", "--user=mysql"]
