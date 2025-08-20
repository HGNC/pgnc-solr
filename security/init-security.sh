#!/bin/bash
set -e

# Wait for Solr to start
echo "Waiting for Solr to be ready..."
until curl -s "http://localhost:${SOLR_PORT}/solr/admin/ping" > /dev/null; do
  sleep 2
done

# Check if security is already configured
if curl -s -f "http://localhost:${SOLR_PORT}/solr/admin/authentication" > /dev/null 2>&1; then
  echo "Security already configured, skipping initialization"
  exit 0
fi

# Copy security.json to the correct location
if [ ! -f /var/solr/data/security.json ]; then
  echo "Copying security configuration..."
  cp /var/solr/security/security.json /var/solr/data/security.json
  chown solr:solr /var/solr/data/security.json
  chmod 600 /var/solr/data/security.json
fi

echo "Security configuration applied."