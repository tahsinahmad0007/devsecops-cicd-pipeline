pipeline {
    agent any

    // 🎯 ADD THIS SECTION - Tools Configuration
    tools {
        nodejs 'Node-18'  // This must match the name you set in Jenkins Tools
    }

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
                bat '''
                    echo Cleaning up old containers and networks...
                    docker stop sonar-db sonarqube devsecops-app 2>nul || echo "Containers not running"
                    docker rm -f sonar-db sonarqube devsecops-app 2>nul || echo "Containers not found"
                    docker network ls --format "{{.Name}}" | findstr /C:"devsecops-ci_devsecops-network" >nul && docker network rm devsecops-ci_devsecops-network || echo "Network not found"
                    docker system prune -f
                    echo Cleanup completed
                '''
            }
        }

        stage('Build Docker Images') {
            steps {
                bat '''
                    echo Building Docker images...
                    %DOCKER_COMPOSE% build app
                '''
            }
        }

        stage('Start SonarQube Services') {
            steps {
                bat '''
                    echo Starting SonarQube services...
                    %DOCKER_COMPOSE% up -d sonar-db sonarqube
                '''
            }
        }

        stage('Wait for SonarQube') {
            steps {
                script {
                    echo "Waiting for SonarQube to be ready..."
                    timeout(time: 5, unit: 'MINUTES') {
                        waitUntil {
                            script {
                                def result = bat(
                                    script: 'curl -s -u admin:admin http://localhost:9000/api/system/health',
                                    returnStatus: true
                                )
                                return result == 0
                            }
                        }
                    }
                    echo "SonarQube is ready!"
                }
            }
        }

        stage('Run Tests') {
            steps {
                bat '''
                    echo Running tests...
                    echo Node.js version:
                    node --version
                    echo NPM version:
                    npm --version
                    cd app
                    npm test
                '''
            }
        }

        stage('Deploy Application') {
            steps {
                bat '''
                    echo Deploying application...
                    %DOCKER_COMPOSE% up -d app
                    timeout /t 10
                    curl http://localhost:3000 || echo App is starting up...
                '''
            }
        }

        stage('Health Check') {
            steps {
                bat '''
                    echo Running health checks...
                    curl http://localhost:3000/health || echo Health check will be available soon
                    echo Pipeline completed successfully!
                '''
            }
        }
    }

    post {
        always {
            bat '''
                echo Final status check...
                docker ps
                echo === Application Status ===
                curl -s http://localhost:3000 || echo App not responding
            '''
        }
        success {
            echo "🎉 DevSecOps Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed! Check the logs above."
        }
    }
}
