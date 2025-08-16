pipeline {
    agent {
        docker {
            image 'docker:24.0.7-dind'
            args '--privileged -v /var/lib/docker'
        }
    }

    environment {
        DOCKER_BUILDKIT = '1'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/sahiliftekhar/secure-cicd-devsecops.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker compose -f docker-compose.yml build'
                }
            }
        }

        stage('Run Container') {
            steps {
                script {
                    sh 'docker compose -f docker-compose.yml up -d'
                }
            }
        }

        stage('Verify App') {
            steps {
                script {
                    sh 'docker ps'
                }
            }
        }
    }
}
