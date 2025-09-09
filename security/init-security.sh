#!/bin/bash
set -e

# Exit if username or password is not set
if [ -z "$SOLR_ADMIN_USER" ] || [ -z "$SOLR_ADMIN_PASSWORD" ]; then
  echo "SOLR_ADMIN_USER and SOLR_ADMIN_PASSWORD must be set. Skipping security setup."
  exit 0
fi

# Check if security is already enabled
if curl -s --user "${SOLR_ADMIN_USER}:${SOLR_ADMIN_PASSWORD}" "http://localhost:8983/solr/admin/authentication" | grep -q '"class":"solr.BasicAuthPlugin"'; then
  echo "Basic Authentication is already enabled."
  exit 0
fi

echo "Enabling Basic Authentication for Solr..."

# Solr requires a SHA-256 hash of the password.
PASSWORD_HASH=$(echo -n "${SOLR_ADMIN_PASSWORD}" | sha256sum | awk '{print $1}')

# Create the credentials JSON object.
CREDENTIALS_JSON="{\"$SOLR_ADMIN_USER\":\"$PASSWORD_HASH\"}"

# Create a temporary security.json from the template, replacing the placeholder.
# The placeholder is a simple string, so we can use sed to replace it with the JSON object.
TEMP_SECURITY_JSON=$(mktemp)
sed "s/\"REPLACE_WITH_CREDS\"/${CREDENTIALS_JSON}/" "/var/solr/security/security.json" > "${TEMP_SECURITY_JSON}"

# Post the new security configuration to Solr.
echo "Applying security configuration..."
# We add --fail to curl to make it exit with an error if the HTTP request fails (e.g., 400 error)
RESPONSE_CODE=$(curl -o /dev/null -s -w "%{http_code}" -X POST -H 'Content-type:application/json' --data-binary "@${TEMP_SECURITY_JSON}" "http://localhost:8983/solr/admin/authentication")

# Clean up the temporary file.
rm "${TEMP_SECURITY_JSON}"

if [ "$RESPONSE_CODE" -eq 200 ]; then
  echo "Basic Authentication has been enabled for user: ${SOLR_ADMIN_USER}"
else
  echo "Error: Failed to apply security configuration. Solr responded with HTTP code: $RESPONSE_CODE"
  echo "Please check the Solr logs for more details."
  exit 1
fi