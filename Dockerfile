FROM jenkins/agent:latest

USER root

# Set up the SSH directory and known_hosts file
RUN mkdir -p ~/.ssh \
        && chmod 700 ~/.ssh \
        && ssh-keyscan -t rsa,ecdsa,ed25519 -H github.com >> ~/.ssh/known_hosts \
        && ssh-keyscan -H projects.onproxmox.sh >> ~/.ssh/known_hosts
        
RUN apt-get update && apt-get install -y rsync ssh && rm -rf /var/lib/apt/lists/*
USER jenkins
