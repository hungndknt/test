#!/usr/bin/env groovy
pipeline {
    agent any
    
    environment {
        PROJECT_NAME = "sample-app"
        PROJECT_DIR = "sample-app/sample-app"
        DOCKER_REGISTRY = "192.168.137.128:18080"
        IMAGE_PREFIX = "ci"
        DOCKERFILE = "Dockerfile"
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        IMAGE_NAME = "${DOCKER_REGISTRY}/${IMAGE_PREFIX}/${PROJECT_NAME}"
        IMAGE_TAG = "${IMAGE_NAME}:${BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                checkout scm
            }
        }
        
        stage('Build Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_TAG} -f Dockerfile sample-app"
                }
            }
        }
        
        stage('Push Image') {
            steps {
                script {
                    sh "docker push ${IMAGE_TAG}"
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    sh """
                        kubectl set image deployment/${PROJECT_NAME} ${PROJECT_NAME}=${IMAGE_TAG} -n default
                        kubectl rollout status deployment/${PROJECT_NAME} -n default
                    """
                }
            }
        }
    }
    
    post {
        always {
            sh "docker rmi ${IMAGE_TAG} || true"
        }
        failure {
            echo 'Build failed!'
        }
        success {
            echo 'Build successful!'
        }
    }
}

