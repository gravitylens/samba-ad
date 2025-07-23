# Samba Active Directory Container

This repository contains a Docker setup for running Samba as an Active Directory Domain Controller.

## Prerequisites

- Docker Engine and Docker Compose
- A network interface on the host that will own the macvlan adapter

## Configuration

1. Copy `.env` and adjust the values for your environment. At a minimum set:
   - `SAMBA_IPV4_ADDRESS` - the static IP for the container
   - `SAMBA_PARENT_INTERFACE` - the host interface to attach the macvlan
   - `SAMBA_DOMAIN`, `SAMBA_REALM`, `SAMBA_ADMIN_PASSWORD`, etc.

2. Run the network helper script to create the macvlan network (requires sudo):

```bash
sudo ./create-network.sh
```

This script validates the IP and creates a Docker network named
`samba_macvlan` bridged to the specified interface.

## Deployment

Start the container using Docker Compose:

```bash
docker compose up -d
```

The Samba AD DC will be accessible at the IP specified in `.env`.

To remove the setup, stop the stack and delete the macvlan network:

```bash
docker compose down
docker network rm samba_macvlan
```

## Troubleshooting

If the container fails to start, ensure the macvlan network exists and that the
chosen IP address is not already in use. The `create-network.sh` script
performs these checks before creating the network.
