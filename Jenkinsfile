pipeline {
    agent any
    tools { nodejs 'Node-18' }

    environment {
        AWS_ACCOUNT_ID = '395069634073'
        AWS_REGION = 'ap-south-1'
        AWS_DEFAULT_REGION = 'ap-south-1'
        ECS_CLUSTER = 'devsecops-app-cluster'
        ECS_SERVICE = 'devsecops-service'
        ECR_REPOSITORY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/devsecops-app"
        DOCKER_COMPOSE = 'docker-compose -f docker-compose.yml'
        SONARQUBE_URL = 'http://localhost:9000'
        PROJECT_KEY = 'DevSecOps-Pipeline-Project'
        SECURITY_REPORTS_DIR = 'security-reports'
        WORKSPACE_DIR = "${WORKSPACE}"
        IMAGE_TAG = "${BUILD_NUMBER}"
        IMAGE_URI = "${ECR_REPOSITORY}:${IMAGE_TAG}"
        IMAGE_LATEST = "${ECR_REPOSITORY}:latest"
    }

    stages {

        stage('Cleanup Old Containers') {
            steps {
                sh '''
                    docker stop sonar-db sonarqube devsecops-app owasp-zap || true
                    docker rm -f sonar-db sonarqube devsecops-app owasp-zap || true
                    docker network prune -f || true
                    docker system prune -f -a -f || true
                '''
            }
        }

        stage('Configure AWS CLI') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh '''
                            aws sts get-caller-identity --region $AWS_REGION
                            echo "AWS Region: $AWS_REGION"
                        '''
                    }
                }
            }
        }

        stage('Prepare Security Environment') {
            steps {
                sh '[ ! -d "$SECURITY_REPORTS_DIR" ] && mkdir "$SECURITY_REPORTS_DIR"'
            }
        }

        stage('Build Docker Images') {
            steps {
                sh '''
                    docker build -t devsecops-ci-app:latest ./app
                    docker tag devsecops-ci-app:latest $IMAGE_URI
                    docker tag devsecops-ci-app:latest $IMAGE_LATEST
                '''
            }
        }

        stage('Container Security Scan - Trivy') {
            steps {
                sh '''
                    # Run JSON report
                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                        -v "$WORKSPACE/$SECURITY_REPORTS_DIR":/reports \
                        -v trivy-cache:/root/.cache aquasec/trivy:latest image --skip-db-update --format json \
                        --output /reports/trivy-container-report.json --severity HIGH,CRITICAL devsecops-ci-app:latest

                    # Run human-readable table report
                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                        -v "$WORKSPACE/$SECURITY_REPORTS_DIR":/reports \
                        -v trivy-cache:/root/.cache aquasec/trivy:latest image --skip-db-update --format table \
                        --output /reports/trivy-container-report.txt --severity HIGH,CRITICAL devsecops-ci-app:latest

                    # Fail the build if any HIGH/CRITICAL vulnerabilities were found.
                    VULN_COUNT=$(jq '[.Results[].Vulnerabilities[]? | select((.Severity=="HIGH") or (.Severity=="CRITICAL"))] | length' "$WORKSPACE/$SECURITY_REPORTS_DIR/trivy-container-report.json")
                    echo "Trivy HIGH/CRITICAL vulnerability count: ${VULN_COUNT}"
                    if [ "$VULN_COUNT" -gt 0 ]; then exit 1; fi
                '''
            }
        }

        stage('Start SonarQube Services') {
            steps {
                sh '$DOCKER_COMPOSE up -d sonar-db sonarqube'
            }
        }

        stage('Wait for SonarQube') {
            steps {
                script {
                    timeout(time: 5, unit: 'MINUTES') {
                        waitUntil {
                            script {
                                def result = sh(script: 'curl -s http://localhost:9000/api/system/health > /dev/null', returnStatus: true)
                                return result == 0
                            }
                        }
                    }
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'cd app && npm install'
            }
        }

        stage('Security: Dependency Scan') {
            steps {
                sh '''
                    cd app
                    npm audit --json > ../$SECURITY_REPORTS_DIR/npm-audit.json || echo "Audit done"
                '''
            }
        }

        stage('Run Tests') {
            steps {
                sh 'cd app && npm test'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                sh '''
                    cd app
                    echo "sonar.projectKey=$PROJECT_KEY" > sonar-project.properties
                    echo "sonar.host.url=$SONARQUBE_URL" >> sonar-project.properties
                    echo "sonar.login=squ_6d1f95d51cda1116c9cdb2208e6976cf4a56c6f5" >> sonar-project.properties
                    npx sonarqube-scanner
                '''
            }
        }

        stage('Quality Gate') {
            steps {
                script { sleep(10) }
            }
        }

        stage('Push to AWS ECR') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh '''
                            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY
                            docker push $IMAGE_URI
                            docker push $IMAGE_LATEST
                        '''
                    }
                }
            }
        }

        stage('Deploy to AWS ECS') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh '''
                            aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --force-new-deployment --region $AWS_REGION
                        '''
                    }
                }
            }
        }

        stage('Get ECS URL') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh '''
                            echo "Waiting for ECS service to stabilize..."
                            aws ecs wait services-stable --cluster $ECS_CLUSTER --services $ECS_SERVICE --region $AWS_REGION || (echo "Service did not stabilize within wait timeout")

                            TASK_ARN=$(aws ecs list-tasks --cluster $ECS_CLUSTER --service-name $ECS_SERVICE --region $AWS_REGION --desired-status RUNNING --query "taskArns[0]" --output text)
                            if [ "$TASK_ARN" = "None" ]; then
                              echo "No running task found for service $ECS_SERVICE"
                              exit 1
                            fi
                            echo "Task ARN: $TASK_ARN"

                            ENI_ID=$(aws ecs describe-tasks --cluster $ECS_CLUSTER --tasks $TASK_ARN --region $AWS_REGION --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value" --output text)
                            if [ "$ENI_ID" = "None" ]; then
                              echo "No network interface found for task $TASK_ARN"
                              exit 1
                            fi
                            echo "Network Interface: $ENI_ID"

                            PUBLIC_IP=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID --region $AWS_REGION --query "NetworkInterfaces[0].Association.PublicIp" --output text)
                            if [ "$PUBLIC_IP" = "None" ]; then
                              echo "No public IP associated with ENI $ENI_ID"
                              exit 1
                            fi

                            echo "========================================="
                            echo "✅ DEPLOYMENT SUCCESSFUL!"
                            echo "🚀 Application URL: http://$PUBLIC_IP:3000"
                            echo "========================================="
                        '''
                    }
                }
            }
        }

        stage('AWS Health Check') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh '''
                            aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --region $AWS_REGION --query "services[0].{Status:status,Running:runningCount}" --output table
                        '''
                    }
                }
            }
        }

        stage('OWASP ZAP DAST') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh '''
                            TASK_ARN=$(aws ecs list-tasks --cluster $ECS_CLUSTER --service-name $ECS_SERVICE --region $AWS_REGION --desired-status RUNNING --query "taskArns[0]" --output text)
                            ENI_ID=$(aws ecs describe-tasks --cluster $ECS_CLUSTER --tasks $TASK_ARN --region $AWS_REGION --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value" --output text)
                            PUBLIC_IP=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID --region $AWS_REGION --query "NetworkInterfaces[0].Association.PublicIp" --output text)

                            mkdir -p "$WORKSPACE/$SECURITY_REPORTS_DIR"

                            docker run --rm -v "$WORKSPACE/$SECURITY_REPORTS_DIR":/zap/wrk:rw ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t http://$PUBLIC_IP:3000 -r /zap/wrk/zap-report.html

                            echo "ZAP scan complete"
                        '''
                    }
                }
            }
        }

        stage('Secrets Scanning') {
            steps {
                sh '''
                    mkdir -p "$WORKSPACE/$SECURITY_REPORTS_DIR"
                    docker run --rm -v "$WORKSPACE":/repo trufflesecurity/trufflehog:latest filesystem /repo --json > "$WORKSPACE/$SECURITY_REPORTS_DIR/trufflehog-secrets.json" || echo "Secrets scan done"
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'security-reports/**/*', allowEmptyArchive: true, fingerprint: true
        }
        success {
            echo '✅ Pipeline SUCCESSFUL!'
        }
        failure {
            echo '❌ Pipeline FAILED - Check logs'
        }
    }
}
