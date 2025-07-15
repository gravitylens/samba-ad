# Samba Active Directory Container

This repository contains a Docker setup for running Samba as an Active Directory Domain Controller.

## Prerequisites

- Docker Engine and Docker Compose
- A network interface on the host that will own the dedicated IP address
- Systemd (used to persist the IP alias)

## Configuration

1. Copy `.env` and adjust the values for your environment. At a minimum set:
   - `SAMBA_IPV4_ADDRESS` - the dedicated IP for the container
   - `SAMBA_PARENT_INTERFACE` - the host interface to bind the alias
   - `SAMBA_DOMAIN`, `SAMBA_REALM`, `SAMBA_ADMIN_PASSWORD`, etc.

2. Run the network helper script to configure the host IP alias (requires sudo):

```bash
sudo ./create-network.sh
```

This script stops any running host Samba services (`smbd`, `nmbd`, `winbindd`) and
adds the IP alias. A systemd service named `samba-ad-ip.service` is created to
reapply the alias on boot.

## Deployment

Start the container using Docker Compose:

```bash
docker compose up -d
```

The Samba AD DC will be accessible at the IP specified in `.env`.

To remove the setup, stop the stack and delete the alias:

```bash
docker compose down
sudo systemctl stop samba-ad-ip.service
```

## Troubleshooting

If the container fails to start due to port conflicts, ensure no other Samba
services are running on the host. The `create-network.sh` script stops them
automatically, but they may have restarted after a reboot.
