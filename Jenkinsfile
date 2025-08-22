#!/usr/bin/env groovy

node {
  properties([disableConcurrentBuilds()])

  try {
    // ====== Vars ======
    dockerRepo     = "192.168.137.128:18080" 
    imagePrefix    = "ci"
    dockerFile     = "Dockerfile"  
    imageName      = "${dockerRepo}/${imagePrefix}/${project}"
    buildNumber    = "${env.BUILD_NUMBER}"

    // ====== Stages ======
    stage('Workspace Clearing') {
      cleanWs()
    }

    stage('Checkout code') {
      checkout scm
      sh "git checkout ${env.BRANCH_NAME} && git reset --hard origin/${env.BRANCH_NAME}"
    }

    stage('Build binary file') {
      // Bỏ test cho nhanh lab; muốn chạy test thì bỏ -DskipTests
      sh "mvn -U -B -DskipTests clean package"
    }

    stage('Build image') {
      sh """
        egrep -q '^FROM .* AS builder\$' ${dockerFile} \
          && docker build -t ${imageName}-stage-builder --target builder -f ${dockerFile} .
        docker build -t ${imageName}:${env.BRANCH_NAME} -f ${dockerFile} .
      """
    }

    stage('Push image') {
      sh """
        docker push ${imageName}:${env.BRANCH_NAME}
        docker tag  ${imageName}:${env.BRANCH_NAME} ${imageName}:${env.BRANCH_NAME}-build-${buildNumber}
        docker push ${imageName}:${env.BRANCH_NAME}-build-${buildNumber}
      """
    }

    imageBuild = "${imageName}:${env.BRANCH_NAME}-build-${buildNumber}"
    echo "Pushed image: ${imageBuild}"

  } catch (e) {
    currentBuild.result = "FAILED"
    throw e
  }
}
