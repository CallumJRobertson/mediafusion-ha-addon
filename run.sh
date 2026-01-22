#!/usr/bin/with-contenv bashio

cd /app
exec uv run python -m comet.main
