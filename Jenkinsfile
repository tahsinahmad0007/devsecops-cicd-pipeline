pipeline {
    agent any

    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker-compose build'
                }
            }
        }

        stage('Run Container') {
            steps {
                script {
                    sh 'docker-compose up -d'
                }
            }
        }
    }
}
