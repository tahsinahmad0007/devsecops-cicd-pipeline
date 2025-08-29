pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "devsecops-ci-app"
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
                script {
                    sh '''
                        echo "Cleaning up old containers (excluding Jenkins)..."
                        docker ps -aq --filter name=devsecops-app | xargs -r docker rm -f
                        docker ps -aq --filter name=sonarqube | xargs -r docker rm -f
                        docker ps -aq --filter name=sonar-db | xargs -r docker rm -f
                        docker images ${DOCKER_IMAGE} -q | xargs -r docker rmi -f
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
        withSonarQubeEnv('MySonarQube') {
            withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONARQUBE_TOKEN')]) {
                script {
                    // Use SonarQube Scanner installed in Jenkins (not inside container)
                    def scannerHome = tool name: 'SonarScanner', type: 'hudson.plugins.sonar.SonarRunnerInstallation'

                    sh """
                        npm test || true

                        ${scannerHome}/bin/sonar-scanner \
                          -Dsonar.projectKey=secure-cicd \
                          -Dsonar.sources=app \
                          -Dsonar.host.url=http://sonarqube:9000 \
                          -Dsonar.login=$SONARQUBE_TOKEN
                    """
                }
            }
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
            steps {
                echo 'Deploying application...'
                // Deployment steps go here
            }
        }
    }
}
