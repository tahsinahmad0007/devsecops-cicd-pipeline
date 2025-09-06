pipeline {
    agent any

    environment {
        DOCKER_COMPOSE = 'docker compose -f docker-compose.yml'
        SONARQUBE_URL = 'http://localhost:9000'
        PROJECT_KEY = 'DevSecOps-Pipeline_Project'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-credentials',  // Updated credential ID
                    url: 'https://github.com/sahiliftekhar/secure-cicd-devsecops.git'
            }
        }

        stage('Cleanup Old Containers') {
            steps {
                sh '''
                    echo "🧹 Cleaning up old containers..."
                    docker ps -aq --filter name=devsecops-app | xargs -r docker rm -f || true
                    docker ps -aq --filter name=sonarqube | xargs -r docker rm -f || true
                    docker ps -aq --filter name=sonar-db | xargs -r docker rm -f || true
                    docker images devsecops-ci-app -q | xargs -r docker rmi -f || true
                '''
            }
        }

        // ... rest of your stages remain the same
    }
}
