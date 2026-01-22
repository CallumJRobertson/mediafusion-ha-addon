ARG BUILD_FROM=ghcr.io/hassio-addons/base:15.0.6
FROM ${BUILD_FROM}

RUN apk update && apk upgrade && \
    apk add --no-cache git nodejs npm

WORKDIR /app

COPY package*.json ./
RUN npm ci --only-production
COPY . .

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD [ "/run.sh" ]
