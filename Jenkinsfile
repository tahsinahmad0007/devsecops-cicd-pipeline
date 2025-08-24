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
                        echo "🔄 Cleaning up old containers and freeing ports..."

                        # Stop and remove app + SonarQube (ignore Jenkins container)
                        docker ps -aq --filter "name=devsecops-app" | xargs -r docker rm -f
                        docker ps -aq --filter "name=sonarqube" | xargs -r docker rm -f
                        docker images "devsecops-ci-app" -q | xargs -r docker rmi -f

                        # Free up port 8080 if any container is blocking it
                        CONTAINER_ID=$(docker ps -q --filter "publish=8080")
                        if [ -n "$CONTAINER_ID" ]; then
                          echo "⚠️ Port 8080 is busy. Stopping container $CONTAINER_ID..."
                          docker stop $CONTAINER_ID
                          docker rm -f $CONTAINER_ID
                        fi
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker compose -f docker-compose.yml build'
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
                withSonarQubeEnv('SonarQube') {
                    sh '''
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
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Deploy') {
            steps {
                echo "🚀 Deployment step goes here (to be implemented later)."
            }
        }
    }
}
