#!/bin/bash
set -e

# Start Solr in the background first
echo "Starting Solr..."
/opt/docker-solr/scripts/docker-entrypoint.sh solr-foreground &
SOLR_PID=$!

# Initialize security
/var/solr/security/init-security.sh

# Wait for the background Solr process
wait $SOLR_PID