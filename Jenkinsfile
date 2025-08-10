pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/sahiliftekhar/secure-cicd-devsecops/devsecops-pipeline.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('app') {
                    script {
                        docker.build("devsecops-app")
                    }
                }
            }
        }
    }
}

