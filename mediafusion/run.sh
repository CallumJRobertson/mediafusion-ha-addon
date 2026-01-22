#!/bin/bash
# MediaFusion Home Assistant Add-on - Main Entry Point
# ==============================================================================

set -e

# Source bashio library (required since init: false disables s6-overlay)
# shellcheck source=/dev/null
source /usr/lib/bashio/bashio.sh

# ==============================================================================
# Configuration Loading
# ==============================================================================

bashio::log.info "Starting MediaFusion Add-on..."

# Read configuration from Home Assistant
HOST_URL=$(bashio::config 'host_url')
SECRET_KEY=$(bashio::config 'secret_key')
API_PASSWORD=$(bashio::config 'api_password')
ENABLE_VPN=$(bashio::config 'enable_vpn')
VPN_KILL_SWITCH=$(bashio::config 'vpn_kill_switch')
LOG_LEVEL=$(bashio::config 'log_level')
ENABLE_TORRENTIO=$(bashio::config 'enable_torrentio_scraping')
ENABLE_ZILEAN=$(bashio::config 'enable_zilean_scraping')
ENABLE_MEDIAFUSION=$(bashio::config 'enable_mediafusion_scraping')
CACHE_TTL=$(bashio::config 'cache_ttl_minutes')
PROWLARR_URL=$(bashio::config 'prowlarr_url')
PROWLARR_API_KEY=$(bashio::config 'prowlarr_api_key')
POSTGRES_DATA_PATH=$(bashio::config 'postgres_data_path')
REDIS_DATA_PATH=$(bashio::config 'redis_data_path')

# Generate secret key if not provided
if [ -z "$SECRET_KEY" ]; then
    SECRET_KEY=$(openssl rand -hex 16)
    bashio::log.warning "No secret key configured - generated temporary key"
fi

# Export environment variables for MediaFusion
export HOST_URL="${HOST_URL}"
export SECRET_KEY="${SECRET_KEY}"
export API_PASSWORD="${API_PASSWORD}"
export LOGGING_LEVEL="${LOG_LEVEL}"
export IS_SCRAP_FROM_TORRENTIO="${ENABLE_TORRENTIO}"
export is_scrap_from_zilean="${ENABLE_ZILEAN}"
export is_scrap_from_mediafusion="${ENABLE_MEDIAFUSION}"
export CACHE_TTL_SECONDS=$((CACHE_TTL * 60))

# Database configuration
export POSTGRES_URI="postgresql+asyncpg://mediafusion:mediafusion@localhost:5432/mediafusion"
export REDIS_URL="redis://localhost:6379"

# Prowlarr configuration (optional)
if [ -n "$PROWLARR_URL" ] && [ -n "$PROWLARR_API_KEY" ]; then
    export PROWLARR_URL="${PROWLARR_URL}"
    export PROWLARR_API_KEY="${PROWLARR_API_KEY}"
    bashio::log.info "Prowlarr integration enabled"
fi

# ==============================================================================
# VPN Setup (Optional)
# ==============================================================================

setup_vpn() {
    if [ "$ENABLE_VPN" = "true" ]; then
        bashio::log.info "Setting up WireGuard VPN..."

        WG_ENDPOINT=$(bashio::config 'wireguard_endpoint')
        WG_PRIVATE_KEY=$(bashio::config 'wireguard_private_key')
        WG_PUBLIC_KEY=$(bashio::config 'wireguard_public_key')
        WG_ADDRESS=$(bashio::config 'wireguard_address')
        WG_DNS=$(bashio::config 'wireguard_dns')

        if [ -z "$WG_ENDPOINT" ] || [ -z "$WG_PRIVATE_KEY" ]; then
            bashio::log.error "VPN enabled but WireGuard configuration is incomplete"
            return 1
        fi

        # Create WireGuard configuration
        mkdir -p /etc/wireguard
        cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = ${WG_PRIVATE_KEY}
Address = ${WG_ADDRESS}
DNS = ${WG_DNS}

[Peer]
PublicKey = ${WG_PUBLIC_KEY}
Endpoint = ${WG_ENDPOINT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

        chmod 600 /etc/wireguard/wg0.conf

        # Get local network to exclude from VPN (preserve LAN access)
        LOCAL_SUBNET=$(ip route | grep -v default | grep -E "^[0-9]" | head -1 | awk '{print $1}')
        LOCAL_GATEWAY=$(ip route | grep default | awk '{print $3}')

        # Set up kill switch if enabled
        if [ "$VPN_KILL_SWITCH" = "true" ]; then
            bashio::log.info "Enabling VPN kill switch..."

            # Allow local network traffic (HA, NAS)
            iptables -A OUTPUT -d 127.0.0.0/8 -j ACCEPT
            iptables -A OUTPUT -d 192.168.0.0/16 -j ACCEPT
            iptables -A OUTPUT -d 172.16.0.0/12 -j ACCEPT
            iptables -A OUTPUT -d 10.0.0.0/8 -j ACCEPT

            # Allow WireGuard endpoint
            WG_ENDPOINT_IP=$(echo "$WG_ENDPOINT" | cut -d: -f1)
            iptables -A OUTPUT -d "$WG_ENDPOINT_IP" -j ACCEPT

            # Allow traffic through WireGuard interface
            iptables -A OUTPUT -o wg0 -j ACCEPT

            # Drop all other outbound traffic
            iptables -A OUTPUT -j DROP
        fi

        # Start WireGuard
        wg-quick up wg0

        # Verify VPN is connected
        if ! wg show wg0 > /dev/null 2>&1; then
            bashio::log.error "Failed to establish VPN connection"
            if [ "$VPN_KILL_SWITCH" = "true" ]; then
                bashio::log.error "Kill switch active - MediaFusion will not have internet access"
            fi
            return 1
        fi

        bashio::log.info "VPN connected successfully"

        # Show VPN status
        PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "unknown")
        bashio::log.info "Public IP: ${PUBLIC_IP}"
    fi
}

# ==============================================================================
# PostgreSQL Setup
# ==============================================================================

setup_postgres() {
    bashio::log.info "Setting up PostgreSQL..."

    # Initialize data directory if needed
    if [ ! -f "${POSTGRES_DATA_PATH}/PG_VERSION" ]; then
        bashio::log.info "Initializing PostgreSQL database..."
        mkdir -p "${POSTGRES_DATA_PATH}"
        chown -R postgres:postgres "${POSTGRES_DATA_PATH}"

        su - postgres -c "initdb -D ${POSTGRES_DATA_PATH} --encoding=UTF8 --locale=C"

        # Configure PostgreSQL for limited resources (MacBook Air)
        cat >> "${POSTGRES_DATA_PATH}/postgresql.conf" << EOF
# MediaFusion optimized settings for low-resource systems
listen_addresses = 'localhost'
port = 5432
max_connections = 50
shared_buffers = 64MB
effective_cache_size = 192MB
maintenance_work_mem = 32MB
work_mem = 4MB
wal_buffers = 4MB
checkpoint_completion_target = 0.9
random_page_cost = 1.1
log_min_messages = warning
log_statement = 'none'
EOF

        # Configure authentication
        cat > "${POSTGRES_DATA_PATH}/pg_hba.conf" << EOF
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
EOF
    fi

    # Start PostgreSQL
    chown -R postgres:postgres "${POSTGRES_DATA_PATH}" /run/postgresql
    su - postgres -c "pg_ctl -D ${POSTGRES_DATA_PATH} -l /data/logs/postgres.log start"

    # Wait for PostgreSQL to be ready
    bashio::log.info "Waiting for PostgreSQL..."
    for i in $(seq 1 30); do
        if su - postgres -c "pg_isready -q"; then
            break
        fi
        sleep 1
    done

    # Create database and user if they don't exist
    su - postgres -c "psql -tc \"SELECT 1 FROM pg_roles WHERE rolname='mediafusion'\" | grep -q 1" || \
        su - postgres -c "createuser mediafusion"

    su - postgres -c "psql -tc \"SELECT 1 FROM pg_database WHERE datname='mediafusion'\" | grep -q 1" || \
        su - postgres -c "createdb -O mediafusion mediafusion"

    bashio::log.info "PostgreSQL ready"
}

# ==============================================================================
# Redis Setup
# ==============================================================================

setup_redis() {
    bashio::log.info "Setting up Redis..."

    mkdir -p "${REDIS_DATA_PATH}"

    # Create Redis configuration optimized for low memory
    cat > /etc/redis.conf << EOF
bind 127.0.0.1
port 6379
daemonize yes
pidfile /var/run/redis.pid
logfile /data/logs/redis.log
loglevel warning
databases 16
dir ${REDIS_DATA_PATH}
maxmemory 64mb
maxmemory-policy allkeys-lru
appendonly yes
appendfsync everysec
save 900 1
save 300 10
save 60 10000
EOF

    # Start Redis
    redis-server /etc/redis.conf

    # Wait for Redis to be ready
    bashio::log.info "Waiting for Redis..."
    for i in $(seq 1 30); do
        if redis-cli ping > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done

    bashio::log.info "Redis ready"
}

# ==============================================================================
# MediaFusion Setup
# ==============================================================================

setup_mediafusion() {
    bashio::log.info "Setting up MediaFusion..."

    cd /app/mediafusion

    # Run database migrations
    bashio::log.info "Running database migrations..."
    if [ -f "alembic.ini" ]; then
        alembic upgrade head 2>/dev/null || bashio::log.warning "Migration failed or already up to date"
    fi
}

# ==============================================================================
# Health Check Loop
# ==============================================================================

health_check_loop() {
    while true; do
        sleep 60

        # Check PostgreSQL
        if ! su - postgres -c "pg_isready -q" 2>/dev/null; then
            bashio::log.error "PostgreSQL is down, attempting restart..."
            su - postgres -c "pg_ctl -D ${POSTGRES_DATA_PATH} start" 2>/dev/null || true
        fi

        # Check Redis
        if ! redis-cli ping > /dev/null 2>&1; then
            bashio::log.error "Redis is down, attempting restart..."
            redis-server /etc/redis.conf
        fi

        # Check VPN if enabled
        if [ "$ENABLE_VPN" = "true" ]; then
            if ! wg show wg0 > /dev/null 2>&1; then
                bashio::log.error "VPN connection lost"
                if [ "$VPN_KILL_SWITCH" = "true" ]; then
                    bashio::log.error "Kill switch active - blocking traffic until VPN reconnects"
                fi
                # Attempt to reconnect
                wg-quick down wg0 2>/dev/null || true
                wg-quick up wg0 2>/dev/null || true
            fi
        fi
    done
}

# ==============================================================================
# Main Entry Point
# ==============================================================================

main() {
    # Create required directories (cont-init.d scripts don't run with init: false)
    bashio::log.info "Creating data directories..."
    mkdir -p /data/postgres
    mkdir -p /data/redis
    mkdir -p /data/cache
    mkdir -p /data/logs
    mkdir -p /run/postgresql

    # Set directory permissions
    chown -R postgres:postgres /data/postgres /run/postgresql 2>/dev/null || true
    chown -R mediafusion:mediafusion /data/cache /data/logs 2>/dev/null || true

    # Setup components
    setup_vpn || bashio::log.warning "VPN setup failed or not enabled"
    setup_postgres
    setup_redis
    setup_mediafusion

    # Start health check in background
    health_check_loop &

    bashio::log.info "Starting MediaFusion server..."
    bashio::log.info "Access URL: ${HOST_URL}"
    bashio::log.info "Manifest URL: ${HOST_URL}/manifest.json"

    cd /app/mediafusion

    # Start MediaFusion with gunicorn (optimized for MacBook Air)
    exec gunicorn api.main:app \
        -w 2 \
        -k uvicorn.workers.UvicornWorker \
        --bind 0.0.0.0:8000 \
        --timeout 120 \
        --max-requests 300 \
        --max-requests-jitter 100 \
        --access-logfile /data/logs/access.log \
        --error-logfile /data/logs/error.log \
        --log-level "${LOG_LEVEL,,}"
}

# Run main function
main "$@"
