pipeline {
    agent any

    environment {
        DOCKER_COMPOSE = 'docker compose -f docker-compose.yml'
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
                withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_TOKEN')]) {
                    script {
                        timeout(time: 15, unit: 'MINUTES') {
                            waitUntil {
                                def response = sh(
                                    script: "curl -s -u ${SONAR_TOKEN}: http://sonarqube:9000/api/system/health | grep -o GREEN || true",
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
            ./gradlew sonarqube \
              -Dsonar.projectKey=secure-cicd-project \
              -Dsonar.host.url=http://sonarqube:9000 \
              -Dsonar.login=$SONAR_TOKEN
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
