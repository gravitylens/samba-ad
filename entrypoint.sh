#!/bin/bash

# Read environment variables
REALM="${REALM:-EXAMPLE.LOCAL}"
DOMAIN="${DOMAIN:-EXAMPLE}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-StrongP@ssw0rd!}"
SERVER_ROLE="${SERVER_ROLE:-dc}"
DNS_FORWARDER="${DNS_FORWARDER:-}"

echo "Samba AD Container Starting"
echo "  Domain:  $DOMAIN"
echo "  Realm:   $REALM"
echo "  Role:    $SERVER_ROLE"

# Configure timezone if TZ is provided
if [ -n "$TZ" ]; then
	ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
	echo "$TZ" >/etc/timezone
fi

# Ensure directories exist (in case volumes are mounted empty)
mkdir -p /var/lib/samba/private /etc/samba /var/log/samba /var/cache/samba

# Provision domain if not already done
if [ ! -f /var/lib/samba/private/secrets.ldb ]; then
	echo "First run detected: provisioning domain..."
	if ! samba-tool domain provision \
		--use-rfc2307 \
		--realm="$REALM" \
		--domain="$DOMAIN" \
		--adminpass="$ADMIN_PASSWORD" \
		--server-role="$SERVER_ROLE" \
		--dns-backend=SAMBA_INTERNAL \
		${DNS_FORWARDER:+--option="dns forwarder = $DNS_FORWARDER"}; then
		echo "❌ Failed to provision domain"
		exit 1
	fi
	echo "✅ Domain provisioned successfully"
else
	echo "Domain already provisioned, skipping."
fi

# Start Samba in foreground
exec /usr/sbin/samba -i
