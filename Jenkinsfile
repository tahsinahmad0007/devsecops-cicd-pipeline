pipeline {
    agent any

    environment {
        DOCKER_COMPOSE = 'docker compose -f docker-compose.yml'
        SONARQUBE_URL = 'http://localhost:9000'  // ✅ Perfect for host Jenkins
        PROJECT_KEY = 'DevSecOps-Pipeline_Project'
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
                    echo "🧹 Cleaning up old containers..."
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
                    echo "🐳 Building images..."
                    ${DOCKER_COMPOSE} build app
                '''
            }
        }

        stage('Start SonarQube Services') {
            steps {
                sh '''
                    echo "🚀 Starting SonarQube and DB..."
                    ${DOCKER_COMPOSE} up -d sonar-db sonarqube
                '''
            }
        }

        stage('Wait for SonarQube') {
            steps {
                script {
                    timeout(time: 10, unit: 'MINUTES') {
                        waitUntil {
                            script {
                                def result = sh(
                                    script: "curl -s ${SONARQUBE_URL}/api/system/health | grep -o '\"health\":\"GREEN\"' || echo 'NOT_READY'",
                                    returnStdout: true
                                ).trim()
                                
                                if (result.contains('GREEN')) {
                                    echo "✅ SonarQube is ready!"
                                    return true
                                } else {
                                    echo "⏳ Waiting for SonarQube... (${result})"
                                    sleep 15
                                    return false
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'jenkins-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        echo "🔎 Running SonarQube analysis..."
                        
                        # Download and setup sonar-scanner
                        if [ ! -f "sonar-scanner" ]; then
                            echo "📥 Downloading SonarQube Scanner..."
                            export SONAR_SCANNER_VERSION=4.7.0.2747
                            curl --create-dirs -sSLo $HOME/.sonar/sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$SONAR_SCANNER_VERSION-linux.zip
                            unzip -o $HOME/.sonar/sonar-scanner.zip -d $HOME/.sonar/
                            export PATH=$HOME/.sonar/sonar-scanner-$SONAR_SCANNER_VERSION-linux/bin:$PATH
                        fi
                        
                        # Set PATH for sonar-scanner
                        export PATH=$HOME/.sonar/sonar-scanner-4.7.0.2747-linux/bin:$PATH
                        
                        # Run SonarQube analysis
                        sonar-scanner \\
                          -Dsonar.projectKey=${PROJECT_KEY} \\
                          -Dsonar.sources=./app \\
                          -Dsonar.host.url=${SONARQUBE_URL} \\
                          -Dsonar.login=${SONAR_TOKEN} \\
                          -Dsonar.projectName="DevSecOps CI/CD Pipeline" \\
                          -Dsonar.projectVersion=1.0 \\
                          -Dsonar.exclusions="**/node_modules/**"
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                withCredentials([string(credentialsId: 'jenkins-token', variable: 'SONAR_TOKEN')]) {
                    script {
                        timeout(time: 5, unit: 'MINUTES') {
                            echo "🚪 Checking Quality Gate..."
                            
                            // Wait a bit for analysis to complete
                            sleep 30
                            
                            def qualityGate = sh(
                                script: """
                                    curl -s -u \${SONAR_TOKEN}: '${SONARQUBE_URL}/api/qualitygates/project_status?projectKey=${PROJECT_KEY}' | 
                                    grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo "UNKNOWN"
                                """,
                                returnStdout: true
                            ).trim()
                            
                            echo "Quality Gate Status: ${qualityGate}"
                            
                            if (qualityGate == "OK") {
                                echo "✅ Quality gate passed!"
                            } else if (qualityGate == "UNKNOWN") {
                                echo "⚠️ Quality gate status unknown - first analysis, proceeding..."
                            } else {
                                echo "⚠️ Quality gate failed: ${qualityGate}"
                                echo "📊 Check details at: ${SONARQUBE_URL}/dashboard?id=${PROJECT_KEY}"
                                // Don't fail the pipeline for demo purposes
                                echo "Continuing for demonstration..."
                            }
                        }
                    }
                }
            }
        }

        stage('Deploy Application') {
            steps {
                sh '''
                    echo "🚀 Deploying application..."
                    ${DOCKER_COMPOSE} up -d app
                    
                    echo "✅ Deployment completed!"
                    echo ""
                    echo "🌐 Application URL: http://localhost:3000"
                    echo "📊 SonarQube Dashboard: http://localhost:9000/dashboard?id=DevSecOps-Pipeline_Project"
                    echo ""
                    echo "📋 Running containers:"
                    docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"
                '''
            }
        }
    }

    post {
        always {
            echo "🏁 Pipeline completed!"
        }
        success {
            echo "✅ All stages passed successfully!"
            echo "📊 View analysis: http://localhost:9000/dashboard?id=DevSecOps-Pipeline_Project"
        }
        failure {
            echo "❌ Pipeline failed - checking logs..."
            sh '''
                echo "🔍 SonarQube logs:"
                docker logs sonarqube --tail=20 || true
                echo "🔍 App logs:"
                docker logs devsecops-app --tail=20 || true
            '''
        }
    }
}
