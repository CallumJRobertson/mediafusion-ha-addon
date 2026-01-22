# MediaFusion Home Assistant Add-on
# Optimized for amd64 (Intel MacBook Air) with limited resources

ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base-python:3.12-alpine3.20
FROM ${BUILD_FROM} AS base

# Build arguments
ARG MEDIAFUSION_VERSION=4.3.35
ARG BUILD_ARCH=amd64

# Labels
LABEL \
    io.hass.name="MediaFusion" \
    io.hass.description="Self-hosted Stremio addon for streaming via debrid services" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${MEDIAFUSION_VERSION}"

# =============================================================================
# Stage 1: Build dependencies
# =============================================================================
FROM base AS builder

WORKDIR /build

# Install build dependencies
RUN apk add --no-cache \
    git \
    curl \
    build-base \
    libffi-dev \
    openssl-dev \
    cargo \
    rust \
    postgresql-dev \
    && pip install --no-cache-dir --upgrade pip uv

# Clone MediaFusion repository
RUN git clone --depth 1 --branch main https://github.com/mhdzumair/MediaFusion.git /build/mediafusion \
    || git clone --depth 1 https://github.com/mhdzumair/MediaFusion.git /build/mediafusion

WORKDIR /build/mediafusion

# Install Python dependencies using uv
RUN uv sync --frozen --no-install-project --compile-bytecode 2>/dev/null || \
    pip install --no-cache-dir \
    fastapi \
    uvicorn[standard] \
    gunicorn \
    pydantic \
    pydantic-settings \
    requests \
    httpx \
    beautifulsoup4 \
    redis[hiredis] \
    sqlmodel \
    asyncpg \
    alembic \
    apscheduler \
    python-dateutil \
    jinja2 \
    bencodepy \
    thefuzz \
    diskcache \
    dramatiq[redis] \
    prometheus-client \
    tenacity \
    ratelimit \
    qrcode \
    pillow \
    pytz \
    tzdata \
    humanize \
    python-multipart

# =============================================================================
# Stage 2: Runtime
# =============================================================================
FROM base AS runtime

# Install runtime dependencies
RUN apk add --no-cache \
    # Database services
    postgresql16 \
    postgresql16-client \
    redis \
    # Networking
    curl \
    wget \
    # WireGuard for optional VPN
    wireguard-tools \
    iptables \
    ip6tables \
    # Process management
    bash \
    jq \
    # Health checks
    netcat-openbsd

# Create mediafusion user
RUN addgroup -g 1000 mediafusion && \
    adduser -D -u 1000 -G mediafusion -h /app mediafusion

# Create necessary directories
RUN mkdir -p \
    /app \
    /data/postgres \
    /data/redis \
    /data/cache \
    /data/logs \
    /run/postgresql \
    /var/lib/postgresql/data \
    && chown -R mediafusion:mediafusion /app /data \
    && chown -R postgres:postgres /run/postgresql /var/lib/postgresql

# Copy Python packages from builder (pip installs to site-packages)
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages

# Copy MediaFusion application
COPY --from=builder /build/mediafusion /app/mediafusion

# Set environment variables
ENV PATH="/app/.venv/bin:/usr/local/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    # MediaFusion defaults
    HOST_URL="http://localhost:8000" \
    POSTGRES_URI="postgresql+asyncpg://mediafusion:mediafusion@localhost:5432/mediafusion" \
    REDIS_URL="redis://localhost:6379" \
    LOGGING_LEVEL="INFO" \
    # Disable unnecessary features for lightweight operation
    DISABLE_ALL_SCHEDULER="false" \
    ENABLE_RATE_LIMIT="false"

# Copy rootfs overlay
COPY rootfs /

# Make scripts executable
RUN chmod +x /etc/cont-init.d/* 2>/dev/null || true \
    && chmod +x /run.sh 2>/dev/null || true

WORKDIR /app/mediafusion

# Expose ports
EXPOSE 8000

# Health check
HEALTHCHECK --interval=60s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Start script
CMD ["/run.sh"]
