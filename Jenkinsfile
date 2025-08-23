pipeline {
    agent any

    environment {
        SONARQUBE = credentials('sonarqube-token')   // replace with your actual credential ID
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/sahiliftekhar/secure-cicd-devsecops.git', branch: 'main'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker compose -f docker-compose.yml build'
                }
            }
        }

        stage('Cleanup Old Containers') {
            steps {
                script {
                    sh '''
                        echo "Cleaning up old containers and images..."
                        docker compose -f docker-compose.yml down || true
                        docker rm -f $(docker ps -aq) || true
                        docker rmi -f $(docker images -aq) || true
                        docker system prune -a --volumes -f || true
                    '''
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
                    sh 'docker ps -a'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        echo "Running SonarQube analysis..."
                        ./sonar-scanner \
                          -Dsonar.projectKey=secure-cicd-devsecops \
                          -Dsonar.sources=. \
                          -Dsonar.host.url=$SONAR_HOST_URL \
                          -Dsonar.login=$SONAR_AUTH_TOKEN
                    '''
                }
            }
        }
    }
}
