#!/bin/bash

# Load .env variables
set -a
source .env
set +a

IFACE="$SAMBA_PARENT_INTERFACE"
CONTAINER_IP="$SAMBA_IPV4_ADDRESS"

if [ -z "$IFACE" ] || [ -z "$CONTAINER_IP" ]; then
	echo "Error: SAMBA_PARENT_INTERFACE or SAMBA_IPV4_ADDRESS is not set in .env"
	exit 1
fi

# Validate network interface
if ! ip link show "$IFACE" >/dev/null 2>&1; then
	echo "Error: Interface '$IFACE' not found."
	exit 1
fi

# Get CIDR (e.g., 192.168.10.25/24)
IP_CIDR=$(ip -4 addr show dev "$IFACE" | awk '/inet / {print $2}')
if [ -z "$IP_CIDR" ]; then
	echo "Error: Could not determine IP/CIDR for interface '$IFACE'"
	exit 1
fi

# Parse CIDR
SUBNET_MASK=$(echo "$IP_CIDR" | cut -d/ -f2)
IFS=/ read -r BASE_IP _ <<<"$IP_CIDR"
IFS=. read -r b1 b2 b3 b4 <<<"$BASE_IP"

# Calculate subnet base as integer
base_ip_int=$(((b1 << 24) + (b2 << 16) + (b3 << 8) + b4))
mask_int=$((0xffffffff << (32 - SUBNET_MASK) & 0xffffffff))
network_int=$((base_ip_int & mask_int))
broadcast_int=$((network_int | ~mask_int & 0xffffffff))

# Convert container IP to integer
IFS=. read -r i1 i2 i3 i4 <<<"$CONTAINER_IP"
container_ip_int=$(((i1 << 24) + (i2 << 16) + (i3 << 8) + i4))

# Check if container IP is within subnet
if ((container_ip_int <= network_int || container_ip_int >= broadcast_int)); then
	echo "❌ Error: IP $CONTAINER_IP is not within subnet $BASE_IP/$SUBNET_MASK"
	exit 1
fi

# Determine actual subnet in CIDR format
subnet_cidr="$(printf "%d.%d.%d.%d" $(((network_int >> 24) & 255)) $(((network_int >> 16) & 255)) $(((network_int >> 8) & 255)) $((network_int & 255)))/$SUBNET_MASK"

# Get gateway for this interface
GATEWAY=$(ip route | awk "/^default.*$IFACE/ {print \$3}")
if [ -z "$GATEWAY" ]; then
	echo "Error: Could not determine gateway for interface '$IFACE'"
	exit 1
fi

# Check if the IP is already in use
if ping -c 1 -W 1 "$CONTAINER_IP" >/dev/null 2>&1; then
	echo "❌ Error: IP $CONTAINER_IP is already in use"
	exit 1
fi

# Create Docker macvlan network if it doesn't already exist
MACVLAN_NAME=samba_macvlan
if docker network inspect "$MACVLAN_NAME" >/dev/null 2>&1; then
	echo "Docker network '$MACVLAN_NAME' already exists."
	exit 0
fi

echo "Creating macvlan network '$MACVLAN_NAME' on $subnet_cidr via $IFACE..."
if docker network create -d macvlan \
	--subnet="$subnet_cidr" \
	--gateway="$GATEWAY" \
	-o parent="$IFACE" \
	"$MACVLAN_NAME"; then
	echo "✅ Successfully created macvlan network '$MACVLAN_NAME'"
else
	echo "❌ Failed to create macvlan network"
	exit 1
fi
