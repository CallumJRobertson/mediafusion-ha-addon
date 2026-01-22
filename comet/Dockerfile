ARG BUILD_FROM=ghcr.io/hassio-addons/base:17.0.0
FROM ${BUILD_FROM}

LABEL name="Comet" \
      description="Stremio's fastest torrent/debrid search add-on." \
      url="https://github.com/g0ldyy/comet"

RUN apk add --no-cache \
    python3 \
    py3-pip \
    gcc \
    python3-dev \
    musl-dev \
    linux-headers \
    git \
    libffi-dev \
    curl-dev \
    openssl-dev \
    cargo \
    rust

RUN pip3 install --no-cache-dir uv

ARG COMET_REPO=https://github.com/g0ldyy/comet
ARG COMET_REF=main

WORKDIR /app

RUN git clone --depth 1 --branch ${COMET_REF} ${COMET_REPO} /app

RUN set -ex && \
    if [ -f pyproject.toml ]; then \
        echo "Found pyproject.toml, installing with uv sync..." && \
        uv sync --no-dev || { echo "uv sync failed, trying pip fallback..."; pip3 install --no-cache-dir .; }; \
    elif [ -f requirements.txt ]; then \
        echo "Found requirements.txt, installing with pip..." && \
        pip3 install --no-cache-dir -r requirements.txt; \
    else \
        echo "ERROR: No dependency manifest found!" && exit 1; \
    fi

COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD ["/run.sh"]
