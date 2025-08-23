# Use official Jenkins LTS as base
FROM jenkins/jenkins:lts

# Switch to root to install packages
USER root

# Install prerequisites & Docker CLI
RUN apt-get update && \
    apt-get install -y \
        curl \
        gnupg2 \
        software-properties-common \
        lsb-release && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
        > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Keep Jenkins running as root for Docker CLI access
USER root
