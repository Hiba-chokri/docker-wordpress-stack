FROM debian:bullseye

# Install PHP-FPM, PHP MySQL extension, wget, and dependencies
RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-intl \
    php7.4-mbstring \
    php7.4-xml \
    php7.4-zip \
    wget \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Create web directory and download WordPress
RUN mkdir -p /var/www/html \
    && wget -q https://wordpress.org/wordpress-6.4.tar.gz \
    && tar -xzf wordpress-6.4.tar.gz -C /var/www/html --strip-components=1 \
    && rm wordpress-6.4.tar.gz \
    && chown -R www-data:www-data /var/www/html

# Install WP-CLI for WordPress management
RUN wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Copy php-fpm configuration
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Copy setup script
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# Create necessary directories for php-fpm
RUN mkdir -p /run/php \
    && chown -R www-data:www-data /run/php

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/setup.sh"]
CMD ["php-fpm7.4", "-F"]
