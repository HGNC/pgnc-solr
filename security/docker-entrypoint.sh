#!/bin/bash
set -e

# Start the original Solr entrypoint in the background, passing the command from the Dockerfile (solr-fg)
/opt/docker-solr/scripts/docker-entrypoint.sh "$@" &
solr_pid=$!

# Wait for the 'pgnc' core to be available before trying to apply security
echo "Waiting for Solr to start and core 'pgnc' to be ready..."
until curl -s "http://localhost:8983/solr/admin/cores?action=STATUS&core=pgnc" | grep -q '"name":"pgnc"'; do
  echo "Solr not ready yet, waiting 5 seconds..."
  sleep 5
done
echo "Solr core 'pgnc' is up."

# Now that Solr is ready, run the security initialization script
echo "Initializing security..."
/var/solr/security/init-security.sh
echo "Security initialization script finished."

# Wait for the Solr process to exit, which will keep the container running
wait $solr_pid