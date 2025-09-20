pipeline {
    agent any

    environment {
        DOCKER_COMPOSE = 'docker compose -f docker-compose.yml'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-pat',
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
                withCredentials([usernamePassword(credentialsId: 'sonar-admin', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    script {
                        timeout(time: 15, unit: 'MINUTES') {
                            waitUntil {
                                def response = sh(
                                    script: "curl -s -u $USERNAME:$PASSWORD http://sonarqube:9000/api/system/health | grep -o GREEN || true",
                                    returnStdout: true
                                ).trim()
                                if (response == "GREEN") {
                                    echo "✅ SonarQube is ready!"
                                    return true
                                } else {
                                    echo "⏳ SonarQube not ready yet, retrying in 10s..."
                                    sleep 10
                                    return false
                                }
                            }
                        }
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
                withCredentials([string(credentialsId: 'jenkins-token', variable: 'SONAR_TOKEN')]) {
                    withSonarQubeEnv('SonarQube') {
                        sh '''
                            echo "🔎 Running SonarQube Scanner..."
                            sonar-scanner \
                              -Dsonar.projectKey=secure-cicd-project \
                              -Dsonar.sources=./app \
                              -Dsonar.host.url=http://sonarqube:9000 \
                              -Dsonar.login=$SONAR_TOKEN \
                              -Dsonar.javascript.node.maxspace=4096 \
                              -Dsonar.sourceEncoding=UTF-8 \
                              -Dsonar.exclusions=**/node_modules/**,**/*.test.js
                        '''
                    }
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
}
