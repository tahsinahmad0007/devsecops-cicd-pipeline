pipeline {
    agent any

    environment {
        DOCKER_COMPOSE = 'docker compose -f docker-compose.yml'
        SONAR_URL = 'http://localhost:9000'
    }

    options {
        timeout(time: 1, unit: 'HOURS')
        retry(3)
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: '41505621-933c-4924-b4e0-e3bf67f60ea9',
                    url: 'https://github.com/sahiliftekhar/secure-cicd-devsecops.git'
            }
        }

        stage('Cleanup Old Containers') {
            steps {
                sh '''
                    echo "🧹 Cleaning up old containers (excluding Jenkins)..."
                    docker ps -aq --filter name=devsecops-app | xargs -r docker rm -f
                    docker ps -aq --filter name=sonarqube | xargs -r docker rm -f
                    docker ps -aq --filter name=sonar-db | xargs -r docker rm -f
                    docker images devsecops-ci-app -q | xargs -r docker rmi -f
                '''
            }
        }

        stage('Build Docker Images') {
            steps {
                sh '''
                    echo "🐳 Building app and SonarQube images..."
                    ${DOCKER_COMPOSE} build app sonarqube
                '''
            }
        }

        stage('Run SonarQube + DB') {
            steps {
                sh '''
                    echo "🚀 Starting SonarQube and DB containers..."
                    ${DOCKER_COMPOSE} up -d sonar-db sonarqube
                '''
            }
        }

        stage('Wait for SonarQube') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'sonar-admin-creds', 
                               usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    script {
                        echo "⏳ Waiting for SonarQube to be ready..."
                        retry(30) {
                            sleep 10
                            def response = sh(
                                script: """
                                    curl -sf -u ${USERNAME}:${PASSWORD} ${SONAR_URL}/api/system/health || echo "FAILED"
                                """,
                                returnStdout: true
                            ).trim()
                            
                            if (!response.contains("GREEN")) {
                                error "SonarQube health check failed: ${response}"
                            }
                        }
                        echo "✅ SonarQube is ready!"
                    }
                }
            }
        }

        stage('Run Application') {
            steps {
                sh '''
                    echo "🚀 Starting Application container..."
                    ${DOCKER_COMPOSE} up -d app
                '''
            }
        }

        stage('Verify Running Containers') {
            steps {
                sh '''
                    echo "🔍 Verifying running containers..."
                    docker ps
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_TOKEN')]) {
                    sh """
                        echo "🔎 Installing SonarScanner..."
                        npm install -g sonarqube-scanner

                        echo "🔍 Running SonarQube Analysis..."
                        sonar-scanner \
                          -Dsonar.projectKey=secure-cicd-project \
                          -Dsonar.sources=. \
                          -Dsonar.host.url=${SONAR_URL} \
                          -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    echo "🚀 Deploying application..."
                    docker ps
                '''
            }
        }
    }

    post {
        always {
            cleanWs()
            sh 'docker system prune -f'
        }
        failure {
            echo '❌ Pipeline failed! Collecting logs...'
            sh '''
                docker logs devsecops-app || true
                docker logs sonarqube || true
                docker logs sonar-db || true
            '''
        }
    }
}
