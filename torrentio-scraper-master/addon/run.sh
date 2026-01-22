#!/usr/bin/with-contenv bashio

port=$(bashio::config 'port')
metrics_user=$(bashio::config 'metrics_user')
metrics_password=$(bashio::config 'metrics_password')
basic_auth_user=$(bashio::config 'basic_auth_user')
basic_auth_password=$(bashio::config 'basic_auth_password')

export PORT="$port"
export METRICS_USER="$metrics_user"
export METRICS_PASSWORD="$metrics_password"
export BASIC_AUTH_USER="$basic_auth_user"
export BASIC_AUTH_PASSWORD="$basic_auth_password"

cd /app || exit 1
exec node --insecure-http-parser index.js
