FROM jenkins/agent:latest

LABEL org.opencontainers.image.source=https://github.com/tripodwire/Jenkins-agent-with-ssh-transfer-extensions

USER root
        
# Install rsync for file transfers. ssh is already included in the base image. Clean up apt cache to reduce image size.
RUN apt-get update && apt-get install -y rsync && rm -rf /var/lib/apt/lists/*

# Copy SSH keyscan setup script and entrypoint
COPY ssh-keyscan-setup.sh /usr/local/bin/ssh-keyscan-setup.sh
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/ssh-keyscan-setup.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

USER jenkins

# Set up the SSH directory
RUN mkdir -p ~/.ssh \
        && chmod 700 ~/.ssh
