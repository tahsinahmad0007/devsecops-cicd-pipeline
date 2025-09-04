pipeline {
    agent any
    
    triggers {
        githubPush()
    }
    
    environment {
        SONAR_TOKEN = credentials('sonarqube-token')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test Webhook') {
            steps {
                echo "GitHub Webhook triggered successfully!"
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'
                    withSonarQubeEnv('SonarQube') {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=devsecops-project \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=http://sonarqube:9000 \
                            -Dsonar.login=\${SONAR_TOKEN}
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
    }
}