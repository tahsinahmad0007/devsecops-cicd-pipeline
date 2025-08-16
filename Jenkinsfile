pipeline {
    agent any

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
                    // Build services inside Jenkins container
                    sh 'docker compose -f docker-compose.yml build'
                }
            }
        }

        stage('Run Container') {
            steps {
                script {
                    // Run services inside Jenkins container
                    sh 'docker compose -f docker-compose.yml up -d'
                }
            }
        }

        stage('Verify Running Containers') {
            steps {
                script {
                    // Check running containers
                    sh 'docker ps'
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up...'
            sh 'docker compose -f docker-compose.yml down || true'
        }
    }
}
