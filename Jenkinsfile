pipeline {
    agent any

    tools {
        // This is CRITICAL. It installs the Sonar Scanner tool so it can be used later.
        // The name 'MySonarScanner' must match the one in Manage Jenkins -> Tools.
        'hudson.plugins.sonar.SonarRunnerInstallation' 'MySonarScanner'
    }

    environment {
        // Define DOCKER_COMPOSE once for cleaner commands
        DOCKER_COMPOSE = 'docker compose -f docker-compose.yml'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: '41505621-933c-4924-b4e0-e3bf67f60ea9', // Ensure this ID is correct
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
                    docker images "devsecops-ci-app" -q | xargs -r docker rmi -f
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

        // --- THIS STAGE HAS BEEN COMPLETELY REWRITTEN FOR RELIABILITY ---
        stage('Wait for SonarQube') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    // This script is more robust and correctly checks the health endpoint
                    waitUntil(initialRecurrencePeriod: 15, quiet: true) {
                        try {
                            // This command will exit with an error if the health isn't GREEN
                            sh(script: "curl -s -f http://sonarqube:9000/api/system/health | grep '\"status\":\"GREEN\"'", returnStatus: false)
                            echo '✅ SonarQube is up and running!'
                            return true // Condition met, exit waitUntil
                        } catch (Exception e) {
                            echo '⏳ SonarQube not ready yet, retrying...'
                            return false // Condition not met, continue retrying
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

        // --- THIS STAGE HAS BEEN CORRECTED ---
        stage('SonarQube Analysis') {
            steps {
                // 'SonarQube' should match the server name in Manage Jenkins -> Configure System
                withSonarQubeEnv('SonarQube') {
                    // 'sonarqube-token' should be the ID of your credential in Jenkins
                    withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                        sh '''
                            echo "🔎 Running SonarQube Scanner..."
                            # CORRECTED: Using sonar-scanner for a Node.js project, not gradlew
                            sonar-scanner \
                                -Dsonar.projectKey=secure-cicd-project \
                                -Dsonar.sources=. \
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