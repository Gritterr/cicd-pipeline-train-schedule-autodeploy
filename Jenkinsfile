// CI/CD for the Train Schedule app. Every new commit on master is built and
// tested as a Docker image, pushed to Docker Hub, and deployed to Kubernetes.
pipeline {
    // The agent "test-server" has Docker and kubectl, and is the k3s cluster's node
    agent { label 'test-server' }
    environment {
        DOCKER_IMAGE_NAME = 'saviochristopher/train-schedule'
        APP_URL = 'http://localhost:30080'
    }
    triggers {
        // GitHub cannot reach this Jenkins to deliver a webhook, so Jenkins
        // checks the repo for new commits every minute instead
        pollSCM('* * * * *')
    }
    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }
    stages {
        stage('Build & Test Image') {
            steps {
                // The Dockerfile runs the unit tests, so a failing test fails this stage
                sh 'docker build -t "$DOCKER_IMAGE_NAME:$BUILD_NUMBER" -t "$DOCKER_IMAGE_NAME:latest" .'
            }
        }
        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub',
                        usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_TOKEN')]) {
                    sh '''
                        # Log in for this build only, outside the agent user's ~/.docker
                        export DOCKER_CONFIG="$WORKSPACE@tmp/docker"
                        trap 'docker logout >/dev/null; rm -rf "$DOCKER_CONFIG"' EXIT
                        echo "$DOCKER_TOKEN" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push "$DOCKER_IMAGE_NAME:$BUILD_NUMBER"
                        docker push "$DOCKER_IMAGE_NAME:latest"
                    '''
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                // Fill in this build's image tag, apply, and wait for the rolling update
                sh '''
                    export KUBECONFIG="$HOME/.kube/config"
                    envsubst '$DOCKER_IMAGE_NAME $BUILD_NUMBER' < k8s/train-schedule.yml | kubectl apply -f -
                    kubectl rollout status deployment/train-schedule-deployment --timeout=180s
                '''
            }
            post {
                failure {
                    // The new pods never became ready: go back to the previous version
                    sh 'KUBECONFIG="$HOME/.kube/config" kubectl rollout undo deployment/train-schedule-deployment || true'
                }
            }
        }
        stage('Smoke Test') {
            steps {
                sh '''
                    curl -fsS "$APP_URL/" | grep -q "Find your train"
                    curl -fsS "$APP_URL/trains" | grep -q '"name"'
                    echo "Deployed $DOCKER_IMAGE_NAME:$BUILD_NUMBER: http://10.79.140.67:30080/"
                '''
            }
            post {
                failure {
                    sh 'KUBECONFIG="$HOME/.kube/config" kubectl rollout undo deployment/train-schedule-deployment || true'
                }
            }
        }
    }
    post {
        always {
            // The cluster pulls images from Docker Hub, so the agent keeps only :latest
            sh 'docker rmi "$DOCKER_IMAGE_NAME:$BUILD_NUMBER" >/dev/null 2>&1 || true; docker image prune -f >/dev/null'
        }
    }
}
