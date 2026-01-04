FROM debian:bullseye

# Install nginx and openssl
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Create SSL directory
RUN mkdir -p /etc/nginx/ssl

# Generate self-signed TLS certificate
ARG DOMAIN_NAME=localhost
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=${DOMAIN_NAME}"

# Copy nginx configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Expose HTTPS port only
EXPOSE 443

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
