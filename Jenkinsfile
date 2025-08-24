pipeline {
    agent any

    environment {
        SONARQUBE_ENV = credentials('sonarqube-token')
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

                        # Remove old images of app only (keep Jenkins & SonarQube safe)
                        docker images "devsecops-ci-app" -q | xargs -r docker rmi -f
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building app and SonarQube images..."
                    pwd
                    ls -R   # Debug: show all files Jenkins sees
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
                withSonarQubeEnv('MySonarQube') {
                    sh '''
                        echo "Waiting for SonarQube to be ready..."
                        sleep 20
                        docker exec devsecops-app npm test || true
                        sonar-scanner \
                          -Dsonar.projectKey=secure-cicd \
                          -Dsonar.sources=. \
                          -Dsonar.host.url=http://sonarqube:9000 \
                          -Dsonar.login=$SONARQUBE_ENV
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
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
                    # For Phase 1, just keep app running (already up via docker-compose)
                '''
            }
        }
    }
}
