#!/usr/bin/with-contenv bashio

# 1. Export Config Options as Environment Variables
export COMET_API_KEY=$(bashio::config 'comet_api_key')
export DEBRID_SERVICE=$(bashio::config 'debrid_service')
export DEBRID_API_KEY=$(bashio::config 'debrid_api_key')
export INDEXER_MANAGER_URL=$(bashio::config 'indexer_manager_url')
export INDEXER_MANAGER_API_KEY=$(bashio::config 'indexer_manager_api_key')

# 2. Persist Database
# Point the database to /data so it survives restarts
export DATABASE_TYPE="sqlite"
export DATABASE_URL="sqlite:////data/comet.db"

# 3. Run Comet
echo "Starting Comet..."
cd /app
# Run directly with python since we installed to system packages in Dockerfile
exec python3 -m comet.main
