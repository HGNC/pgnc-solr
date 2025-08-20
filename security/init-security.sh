#!/bin/bash
set -e

# Wait for Solr to start
echo "Waiting for Solr to be ready..."
until curl -s "http://localhost:${SOLR_PORT}/solr/admin/ping" > /dev/null; do
  sleep 2
done

echo "Solr is ready. Setting up BasicAuth authentication with user: ${SOLR_USERNAME}"

# Set up both authentication and authorization in one call to avoid sequencing issues
echo "Configuring authentication and authorization..."
curl -X POST "http://localhost:${SOLR_PORT}/solr/admin/authentication" \
  -H 'Content-Type: application/json' \
  -d "{
    \"set-property\": {
      \"blockUnknown\": true,
      \"class\": \"solr.BasicAuthPlugin\"
    },
    \"set-user\": {\"${SOLR_USERNAME}\": \"${SOLR_PASSWORD}\"}
  }"

sleep 3

# Now set up authorization in a separate call
curl -X POST "http://localhost:${SOLR_PORT}/solr/admin/authorization" \
  -u "${SOLR_USERNAME}:${SOLR_PASSWORD}" \
  -H 'Content-Type: application/json' \
  -d "{
    \"set-property\": {
      \"class\": \"solr.RuleBasedAuthorizationPlugin\"
    },
    \"set-permission\": {\"name\": \"all\", \"role\": \"admin\"},
    \"set-user-role\": {\"${SOLR_USERNAME}\": \"admin\"}
  }"

echo "Security configuration completed successfully!"
echo "Authentication enabled for user: ${SOLR_USERNAME}"

# Test that authentication is working
echo "Testing authentication..."
if curl -f -u "${SOLR_USERNAME}:${SOLR_PASSWORD}" -s "http://localhost:${SOLR_PORT}/solr/admin/authentication" > /dev/null; then
  echo "Authentication test passed!"
else
  echo "Authentication test failed!"
fi