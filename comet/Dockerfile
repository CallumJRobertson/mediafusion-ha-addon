ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base:7.3.3
FROM ${BUILD_FROM}

LABEL name="Comet" \
      description="Stremio's fastest torrent/debrid search add-on." \
      url="https://github.com/g0ldyy/comet"

# Install Python and basic build tools (Debian)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-dev \
        git \
        build-essential \
        libffi-dev \
        libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install uv for fast dependency management
RUN pip3 install --no-cache-dir uv --break-system-packages

ARG COMET_REPO=https://github.com/g0ldyy/comet
ARG COMET_REF=main

WORKDIR /app

# Clone the Comet repository
RUN git clone --depth 1 --branch ${COMET_REF} ${COMET_REPO} /app

# Install dependencies into the SYSTEM python environment (avoids venv complexity)
# We check for requirements.txt or pyproject.toml
RUN uv pip install --system --no-cache -r requirements.txt || uv pip install --system --no-cache .

COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD ["/run.sh"]
