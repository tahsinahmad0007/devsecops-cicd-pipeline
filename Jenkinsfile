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
                        echo "Cleaning up old containers (app + SonarQube only)..."

                        # Stop and remove app + SonarQube only (NOT Jenkins!)
                        docker ps -aq --filter "name=devsecops-app" | xargs -r docker rm -f
                        docker ps -aq --filter "name=sonarqube" | xargs -r docker rm -f

                        # Remove old app image only
                        docker images "devsecops-ci-app" -q | xargs -r docker rmi -f
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker compose -f docker-compose.yml build app sonarqube'
            }
        }

        stage('Run Containers') {
            steps {
                sh 'docker compose -f docker-compose.yml up -d app sonarqube'
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
    }
}
