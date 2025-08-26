pipeline {
    agent any

    tools {
        // This tells Jenkins to use the SonarQube Scanner tool you configured.
        // The name 'MySonarScanner' MUST match the name you gave it in 
        // Manage Jenkins -> Tools.
        sonarscanner 'MySonarScanner'
    }

    stages {

        stage('Checkout') {
            steps {
                git url: 'https://github.com/sahiliftekhar/secure-cicd-devsecops.git', branch: 'main'
            }
        }

        stage('Cleanup Old Containers') {
            steps {
                script {
                    sh '''
                        echo "Cleaning up old containers (excluding Jenkins)..."
                        # Stop and remove only specific containers
                        docker ps -aq --filter "name=devsecops-app" | xargs -r docker rm -f
                        docker ps -aq --filter "name=sonarqube" | xargs -r docker rm -f
                        docker ps -aq --filter "name=sonar-db" | xargs -r docker rm -f
                        # Remove old images of app only
                        docker images "devsecops-ci-app" -q | xargs -r docker rmi -f
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building app and SonarQube images..."
                    docker compose -f docker-compose.yml build app sonarqube
                '''
            }
        }

        stage('Run Container') {
            steps {
                sh 'docker compose -f docker-compose.yml up -d'
            }
        }

        stage('Verify Running Containers') {
            steps {
                sh 'docker ps'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                // 'MySonarQube' should match the server name in Manage Jenkins -> Configure System
                withSonarQubeEnv('MySonarQube') {
                    // 'sonarqube-token' is the ID of your credential in Jenkins
                    withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONARQUBE_TOKEN')]) {
                        sh '''
                            docker exec devsecops-app npm test || true
                            
                            # The 'tools' block added 'sonar-scanner' to the PATH, so we can call it directly.
                            sonar-scanner \
                                -Dsonar.projectKey=secure-cicd \
                                -Dsonar.sources=. \
                                -Dsonar.host.url=http://sonarqube:9000 \
                                -Dsonar.login=$SONARQUBE_TOKEN
                        '''
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    // This step checks the SonarQube quality gate result
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Deploy') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                sh '''
                    echo "Deploying Application..."
                    # Deployment steps would go here
                '''
            }
        }
    }
}