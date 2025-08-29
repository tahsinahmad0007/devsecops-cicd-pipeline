pipeline {
    agent any

    environment {
        SONARQUBE_ENV = 'MySonarQube'   // Jenkins SonarQube server config
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/sahiliftekhar/secure-cicd-devsecops.git',
                    credentialsId: '41505621-933c-4924-b4e0-e3bf67f60ea9'
            }
        }

        stage('Cleanup Old Containers') {
            steps {
                sh '''
                    echo "Cleaning up old containers (excluding Jenkins)..."
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
                    echo "Building app and SonarQube images..."
                    docker compose -f docker-compose.yml build app sonarqube
                '''
            }
        }

        stage('Run Containers') {
            steps {
                sh 'docker compose -f docker-compose.yml up -d'
            }
        }

        stage('Verify Running Containers') {
            steps {
                sh 'docker ps'
            }
        }

        stage('Wait for SonarQube') {
            steps {
                script {
                    timeout(time: 7, unit: 'MINUTES') {   // keep retrying for 7 mins
                        waitUntil {
                            def status = sh(
                                script: 'curl -s http://sonarqube:9000/api/system/health | grep -o \'"status":"UP"\' || true',
                                returnStdout: true
                            ).trim()
                            if (status == '"status":"UP"') {
                                echo "✅ SonarQube is UP!"
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

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONARQUBE_TOKEN')]) {
                        sh '''
                            echo "Running tests inside app container..."
                            docker exec devsecops-app npm test || true

                            echo "Running SonarQube scanner..."
                            $SONAR_SCANNER_HOME/bin/sonar-scanner \
                              -Dsonar.projectKey=secure-cicd \
                              -Dsonar.sources=app \
                              -Dsonar.host.url=http://sonarqube:9000 \
                              -Dsonar.login=$SONARQUBE_TOKEN
                        '''
                    }
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
                echo '🚀 Deploying Application...'
            }
        }
    }
}
