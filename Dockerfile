# Use Debian as base
FROM debian:bullseye

# Install Samba AD packages, Kerberos, and DNS utilities
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    samba samba-dsdb-modules winbind krb5-config krb5-user \
    dnsutils net-tools && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Expose required ports for AD services
EXPOSE 53 88 135 137/udp 138/udp 139 389 445 464 636 3268 3269

# Define persistent volumes
VOLUME /etc/samba /var/lib/samba /var/cache/samba /var/log/samba

# Copy entrypoint script into image
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Run entrypoint script to provision if needed and start samba
CMD ["/entrypoint.sh"]
