FROM jenkins/agent:latest

USER root

# Set up the SSH directory
RUN mkdir -p ~/.ssh \
        && chmod 700 ~/.ssh
        
RUN apt-get update && apt-get install -y rsync ssh gosu && rm -rf /var/lib/apt/lists/*

# Copy SSH keyscan setup script and entrypoint
COPY ssh-keyscan-setup.sh /usr/local/bin/ssh-keyscan-setup.sh
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/ssh-keyscan-setup.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

USER jenkins
