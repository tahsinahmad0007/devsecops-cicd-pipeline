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

        stage('Verify Running Containers') {
            steps {
                script {
                    sh 'docker ps'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQubeServer') {  // <-- Use the exact name from Jenkins global config
                    sh 'sonar-scanner -Dsonar.projectKey=secure-cicd-devsecops -Dsonar.sources=.'
                }
            }
        }
    }
}
