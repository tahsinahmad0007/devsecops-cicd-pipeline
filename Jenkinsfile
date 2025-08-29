pipeline {
    agent any

    environment {
        DOCKER_COMPOSE = 'docker compose -f docker-compose.yml'
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
                sh '''
                    echo "🧹 Cleaning up old containers (excluding Jenkins)..."
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
                    echo "🐳 Building app and SonarQube images..."
                    ${DOCKER_COMPOSE} build app sonarqube
                '''
            }
        }

        stage('Run Containers') {
            steps {
                sh '''
                    echo "🚀 Starting containers..."
                    ${DOCKER_COMPOSE} up -d app sonarqube db
                '''
            }
        }

        stage('Verify Running Containers') {
            steps {
                sh '''
                    echo "🔍 Verifying running containers..."
                    docker ps
                '''
            }
        }

        stage('Wait for SonarQube') {
  steps {
    script {
      timeout(time: 7, unit: 'MINUTES') {
        waitUntil {
          def res = sh(script: "curl -s http://sonarqube:9000/api/system/health | grep -o 'GREEN' || true",
                       returnStdout: true).trim()
          if (res != 'GREEN') {
            echo '⏳ SonarQube not ready yet, retrying in 10s...'
            sleep 10
            return false
          }
          true
        }
      }
    }
  }
}


        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        echo "🔎 Running SonarQube Scanner..."
                        ./gradlew sonarqube \
                          -Dsonar.projectKey=secure-cicd-project \
                          -Dsonar.host.url=http://sonarqube:9000 \
                          -Dsonar.login=$SONARQUBE_TOKEN
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
            steps {
                sh '''
                    echo "🚀 Deploying application..."
                    docker ps
                '''
            }
        }
    }
}
