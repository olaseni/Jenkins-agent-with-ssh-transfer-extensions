FROM jenkins/agent:latest

LABEL org.opencontainers.image.source=https://github.com/tripodwire/Jenkins-agent-with-ssh-transfer-extensions

USER root
        
# Install rsync for file transfers. ssh is already included in the base image. Clean up apt cache to reduce image size.
RUN apt-get update && apt-get install -y \
    rsync \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Copy SSH keyscan setup script, wrapper, and entrypoint
COPY ssh-keyscan-setup.sh /usr/local/bin/ssh-keyscan-setup.sh
COPY ssh-wrapper.sh /usr/local/bin/ssh-wrapper.sh
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Create a memorable soft link for keyscan script, install SSH wrapper, and make scripts executable
RUN ln -s /usr/local/bin/ssh-keyscan-setup.sh /usr/local/bin/scan_configured_host_keys \
    && chmod +x /usr/local/bin/ssh-keyscan-setup.sh \
    && chmod +x /usr/local/bin/scan_configured_host_keys \
    && chmod +x /usr/local/bin/ssh-wrapper.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh \
    && mv /usr/bin/ssh /usr/bin/ssh.real \
    && ln -s /usr/local/bin/ssh-wrapper.sh /usr/bin/ssh

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

USER jenkins

# Set up the SSH directory
RUN mkdir -p ~/.ssh \
        && chmod 700 ~/.ssh
