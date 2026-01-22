ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base:7.8.1
FROM ${BUILD_FROM}

LABEL name="Comet" \
      description="Stremio's fastest torrent/debrid search add-on." \
      url="https://github.com/g0ldyy/comet"

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    git \
    && rm -rf /var/lib/apt/lists/*

ARG COMET_REPO=https://github.com/g0ldyy/comet
ARG COMET_REF=main

WORKDIR /app

RUN git clone --depth 1 --branch ${COMET_REF} ${COMET_REPO} /app

RUN python3 -m pip install --no-cache-dir --break-system-packages .

COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD ["/run.sh"]
