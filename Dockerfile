# Dockerfile for USB-Beamer-server

# Use Ubuntu 24.04 as base image
FROM ubuntu:24.04

# Set environment variables to non-interactive to avoid prompts during installation.
ENV DEBIAN_FRONTEND=noninteractive
ENV TUNNEL_PORT=8007

# Update package lists and install necessary packages.
# - openssh-server: for SSH access.
# - avahi-daemon: for network service discovery.
# - usbip: for sharing USB devices over the network.
# - python3 and python3-pip: for the Python application.
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    avahi-daemon \
    usbip \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Flask using pip.
RUN pip3 install Flask

# Create a non-root user 'tunnel' for SSH access.
# This user has no password and a non-interactive shell for security.
# You will need to add a public key to /home/tunnel/.ssh/authorized_keys
# to allow SSH access. You can do this by adding a COPY instruction like:
# COPY your_public_key.pub /home/tunnel/.ssh/authorized_keys
RUN useradd --create-home --shell /usr/sbin/nologin tunnel && \
    mkdir -p /home/tunnel/.ssh && \
    touch /home/tunnel/.ssh/authorized_keys && \
    chown -R tunnel:tunnel /home/tunnel/.ssh && \
    chmod 700 /home/tunnel/.ssh && \
    chmod 600 /home/tunnel/.ssh/authorized_keys

# Create a directory for the SSH daemon.
RUN mkdir /var/run/sshd

# Configure SSH for key-based authentication and tunneling only on a configurable port.
# The port is set by the TUNNEL_PORT environment variable. For runtime configuration,
# this command should be moved to an entrypoint script.
# Password authentication and root login are disabled.
# Shell access is disabled to enhance security, allowing only tunneling.
# A user with an authorized public key will be required for access.
RUN sed -i "s/^#?Port .*/Port $TUNNEL_PORT/" /etc/ssh/sshd_config && \
    sed -i 's/^#?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/^#?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    echo "ForceCommand /usr/sbin/nologin" >> /etc/ssh/sshd_config

# Expose ports for SSH and the web application.
EXPOSE ${TUNNEL_PORT}
EXPOSE 5000

# Set the working directory for the application.
WORKDIR /app

# Copy the application code into the container.
COPY . /app

# The command to run when the container starts.
# This is a placeholder and should be replaced with a script that starts
# all the necessary services (sshd, avahi-daemon, Flask app).
CMD ["/bin/bash", "-c", "echo 'Container started. Run services manually for now.'; tail -f /dev/null"] 