pipeline {
    agent any

    tools {
        // This must match the SonarScanner installation name in Jenkins Global Tool Config
        SonarQubeScanner 'SonarScanner'
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

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('MySonarQube') {   // Name must match the SonarQube server you added in Jenkins System Config
                    sh '''
                        sonar-scanner \
                          -Dsonar.projectKey=secure-cicd-devsecops \
                          -Dsonar.sources=. \
                          -Dsonar.host.url=http://sonarqube:9000 \
                          -Dsonar.login=${SONAR_AUTH_TOKEN}
                    '''
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
    }

    post {
        always {
            echo "Cleaning up..."
            sh 'docker compose -f docker-compose.yml down || true'
        }
    }
}
