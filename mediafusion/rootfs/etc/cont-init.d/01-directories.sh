#!/usr/bin/with-contenv bashio
# ==============================================================================
# Create necessary directories
# ==============================================================================

bashio::log.info "Creating data directories..."

# Create data directories with proper permissions
mkdir -p /data/postgres
mkdir -p /data/redis
mkdir -p /data/cache
mkdir -p /data/logs
mkdir -p /run/postgresql

# Set permissions
chown -R postgres:postgres /data/postgres /run/postgresql
chown -R redis:redis /data/redis 2>/dev/null || chown -R root:root /data/redis
chown -R mediafusion:mediafusion /data/cache /data/logs 2>/dev/null || true

bashio::log.info "Directories ready"
