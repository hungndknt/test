#!/usr/bin/env groovy
pipeline {
  agent any

  environment {
    PROJECT_NAME   = "sample-app"
    DOCKER_REGISTRY= "192.168.137.128:18080"
    IMAGE_PREFIX   = "ci"
    IMAGE_NAME     = "${DOCKER_REGISTRY}/${IMAGE_PREFIX}/${PROJECT_NAME}"
    IMAGE_TAG      = "${IMAGE_NAME}:${env.BUILD_NUMBER}"
    DOCKERFILE_PATH= "Dockerfile"
    BUILD_CONTEXT  = "." 
  }

  stages {
    stage('Checkout') {
      steps { cleanWs(); checkout scm }
    }

    stage('Build Image') {
      steps {
        sh """
          docker build -t ${IMAGE_TAG} -f ${DOCKERFILE_PATH} ${BUILD_CONTEXT}
        """
      }
    }

    stage('Push Image') {
      steps {
        sh "docker push ${IMAGE_TAG}"
      }
    }

    stage('Deploy') {
      steps {
        sh """
          kubectl -n default set image deployment/${PROJECT_NAME} ${PROJECT_NAME}=${IMAGE_TAG}
          kubectl -n default rollout status deployment/${PROJECT_NAME}
        """
      }
    }
  }

  post {
    always  { sh "docker rmi ${IMAGE_TAG} || true" }
    failure { echo 'Build failed!' }
    success { echo 'Build successful!' }
  }
}
