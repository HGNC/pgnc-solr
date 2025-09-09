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

# Create the JSON objects for credentials and user-role mapping.
CREDENTIALS_JSON="{\"$SOLR_ADMIN_USER\":\"$PASSWORD_HASH\"}"
USER_ROLE_JSON="{\"$SOLR_ADMIN_USER\":\"admin\"}"

# Create a temporary security.json from the template, replacing the placeholders.
TEMP_SECURITY_JSON=$(mktemp)
sed "s/\"REPLACE_WITH_CREDS\"/${CREDENTIALS_JSON}/" "/var/solr/security/security.json" | \
sed "s/\"REPLACE_WITH_USER_ROLE\"/${USER_ROLE_JSON}/" > "${TEMP_SECURITY_JSON}"


# Post the new security configuration to Solr.
echo "Applying security configuration..."
RESPONSE_CODE=$(curl -o /dev/null -s -w "%{http_code}" -X POST -H 'Content-type:application/json' --data-binary "@${TEMP_SECURITY_JSON}" "http://localhost:8983/solr/admin/authentication")

# Clean up the temporary file.
rm "${TEMP_SECURITY_JSON}"

if [ "$RESPONSE_CODE" -eq 200 ]; then
  echo "Basic Authentication has been enabled for user: ${SOLR_ADMIN_USER}"
else
  echo "Error: Failed to apply security configuration. Solr responded with HTTP code: $RESPONSE_CODE"
  # Print the content of the JSON we tried to send, for debugging.
  echo "Attempted to send the following configuration:"
  cat "${TEMP_SECURITY_JSON}"
  exit 1
fi