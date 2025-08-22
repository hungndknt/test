#!/usr/bin/env groovy

node {
  properties([disableConcurrentBuilds()])

  try {
    // ===== Vars =====
    def project     = "sample-app"
    def dockerRepo  = "192.168.137.128:18080"
    def imagePrefix = "ci"
    def dockerFile  = "Dockerfile"
    def imageName   = "${dockerRepo}/${imagePrefix}/${project}"
    def buildNumber = env.BUILD_NUMBER
    def branchName  = env.BRANCH_NAME   // có thể null nếu không chạy multibranch

    stage('Workspace Clearing') {
      cleanWs()
    }

    stage('Checkout code') {
      checkout scm
      // Chỉ checkout/reset khi có BRANCH_NAME
      if (branchName) {
        sh """
          git fetch --all --prune
          git checkout -B ${branchName} origin/${branchName}
          git reset --hard origin/${branchName}
        """
      } else {
        echo "No BRANCH_NAME detected; using current checked-out commit."
      }
    }

    stage('Build binary file') {
      sh "mvn -U -B -DskipTests clean package"
    }

    stage('Build image') {
      sh """#!/bin/bash -e
        if egrep -q '^FROM .* AS (builder|build-stage)\$' ${dockerFile}; then
          docker build -t ${imageName}-stage-builder --target builder -f ${dockerFile} .
        fi
        docker build -t ${imageName}:${branchName ?: 'manual'} -f ${dockerFile} .
      """
    }

    stage('Push image') {
      def tagBase = (branchName ?: 'manual')
      sh """
        docker push ${imageName}:${tagBase}
        docker tag  ${imageName}:${tagBase} ${imageName}:${tagBase}-build-${buildNumber}
        docker push ${imageName}:${tagBase}-build-${buildNumber}
      """
    }

    def imageBuild = "${imageName}:${(branchName ?: 'manual')}-build-${buildNumber}"
    echo "Pushed image: ${imageBuild}"

  } catch (e) {
    currentBuild.result = "FAILED"
    throw e
  }
}
