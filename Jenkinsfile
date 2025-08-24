pipeline {
    agent any

    environment {
        SONARQUBE_ENV = credentials('sonarqube-token')
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/sahiliftekhar/secure-cicd-devsecops.git'
            }
        }

        stage('Cleanup Old Containers') {
            steps {
                script {
                    sh '''
                        echo "Cleaning up old containers (excluding Jenkins)..."

                        # Remove specific containers if running
                        docker ps -aq --filter "name=devsecops-app" | xargs -r docker rm -f
                        docker ps -aq --filter "name=sonarqube" | xargs -r docker rm -f

                        # Remove old app images only
                        docker images "devsecops-ci-app" -q | xargs -r docker rmi -f
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
                        # Optional: run tests (comment if not needed)
                        # docker exec devsecops-app npm test || true

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
    }
}
