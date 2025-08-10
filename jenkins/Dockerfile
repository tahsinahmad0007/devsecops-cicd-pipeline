FROM jenkins/jenkins:lts

# Skip initial setup wizard
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

# Install Docker CLI (inside Jenkins container)
USER root
RUN apt-get update && \
    apt-get install -y docker.io docker-compose && \
    usermod -aG docker jenkins

USER jenkins

