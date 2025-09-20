# Use official Jenkins LTS as base
FROM jenkins/jenkins:lts

USER root

COPY init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/
RUN chmod -R 755 /usr/share/jenkins/ref/init.groovy.d/

USER jenkins
