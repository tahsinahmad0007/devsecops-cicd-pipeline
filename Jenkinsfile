pipeline {
    agent any

    environment {
        DOCKER_COMPOSE = 'docker-compose -f docker-compose.yml'
        SONARQUBE_URL = 'http://localhost:9000'
        PROJECT_KEY = 'DevSecOps-Pipeline_Project'
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
                    echo "🧹 Cleaning up old containers..."
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
                    echo "🐳 Building Docker images..."
                    ${DOCKER_COMPOSE} build app
                '''
            }
        }

        stage('Start SonarQube Services') {
            steps {
                sh '''
                    echo "🚀 Starting SonarQube services..."
                    ${DOCKER_COMPOSE} up -d sonar-db sonarqube
                '''
            }
        }

        stage('Wait for SonarQube') {
            steps {
                script {
                    echo "⏳ Waiting for SonarQube to be ready..."
                    timeout(time: 10, unit: 'MINUTES') {
                        waitUntil {
                            script {
                                def result = sh(
                                    script: 'curl -s -u admin:admin http://localhost:9000/api/system/health',
                                    returnStatus: true
                                )
                                return result == 0
                            }
                        }
                    }
                    echo "✅ SonarQube is ready!"
                }
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                    echo "🧪 Running tests..."
                    cd app
                    npm test
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'jenkins-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        echo "🔎 Running SonarQube analysis..."
                        cd app
                        sonar-scanner \\
                          -Dsonar.projectKey=${PROJECT_KEY} \\
                          -Dsonar.sources=. \\
                          -Dsonar.host.url=${SONARQUBE_URL} \\
                          -Dsonar.login=${SONAR_TOKEN} \\
                          -Dsonar.exclusions=**/node_modules/**,**/*.test.js
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline aborted due to quality gate failure: ${qg.status}"
                        }
                    }
                }
            }
        }

        stage('Deploy Application') {
            steps {
                sh '''
                    echo "🚀 Deploying application..."
                    ${DOCKER_COMPOSE} up -d app
                    sleep 10
                    curl http://localhost:3000 || echo "App not ready yet"
                '''
            }
        }
    }

    post {
        always {
            sh '''
                echo "📊 Final status check..."
                docker ps
            '''
        }
        success {
            echo "🎉 Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
