#!/bin/bash

# Read environment variables
REALM="${REALM:-EXAMPLE.LOCAL}"
DOMAIN="${DOMAIN:-EXAMPLE}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-StrongP@ssw0rd!}"
SERVER_ROLE="${SERVER_ROLE:-dc}"

echo "\ED\A0\BC\ED\BE\9B Samba AD Container Starting"
echo "\ED\A0\BD\ED\B4\A7 Domain:  $DOMAIN"
echo "\ED\A0\BD\ED\B4\A7 Realm:   $REALM"
echo "\ED\A0\BD\ED\B4\A7 Role:    $SERVER_ROLE"

# Ensure directories exist (in case volumes are mounted empty)
mkdir -p /var/lib/samba/private /etc/samba /var/log/samba /var/cache/samba

# Provision domain if not already done
if [ ! -f /var/lib/samba/private/secrets.ldb ]; then
  echo "\ED\A0\BD\ED\BA\80 First run detected: provisioning domain..."
  samba-tool domain provision \
    --use-rfc2307 \
    --realm="$REALM" \
    --domain="$DOMAIN" \
    --adminpass="$ADMIN_PASSWORD" \
    --server-role="$SERVER_ROLE" \
    --dns-backend=SAMBA_INTERNAL

  if [ $? -ne 0 ]; then
    echo "❌ Failed to provision domain"
    exit 1
  fi
  echo "✅ Domain provisioned successfully"
else
  echo "\ED\A0\BD\ED\B7\82 Domain already provisioned, skipping."
fi

# Start Samba in foreground
exec /usr/sbin/samba -i

