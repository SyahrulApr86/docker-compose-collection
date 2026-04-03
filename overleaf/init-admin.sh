#!/bin/sh

echo "Waiting Overleaf startup..."

sleep 60

echo "Creating admin..."

ACTIVATE_LINK=$(docker exec overleaf /bin/bash -ce "
cd /overleaf/services/web && \
node modules/server-ce-scripts/scripts/create-user \
--admin \
--email=$OVERLEAF_ADMIN_EMAIL
" 2>&1 | grep -o 'http://[^ ]*/user/activate[^ ]*')

echo ""
echo "======================================"
echo "Admin user created: $OVERLEAF_ADMIN_EMAIL"
echo ""
echo "Open this link to set password:"
echo ""
echo "$ACTIVATE_LINK"
echo ""
echo "======================================"