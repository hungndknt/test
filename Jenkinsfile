#!/usr/bin/env groovy
node {
  properties([disableConcurrentBuilds()])

  try {
    // ===== Vars =====
    def project        = "sample-app"
    def dockerRepo     = "192.168.137.128:18080"
    def imagePrefix    = "ci"
    def dockerFile     = "Dockerfile"
    def imageName      = "${dockerRepo}/${imagePrefix}/${project}"
    def buildNumber    = env.BUILD_NUMBER
    def branchName     = env.BRANCH_NAME ?: "main"
    def dockerCredId   = "Harbor" 

    // K8s
    def k8sProjectName = "sample-app"      
    def namespace      = "default"

  // Maven tool
    def mvnHome = tool 'apache-maven-3.9.11'

    stage('Workspace Clearing') { cleanWs() }

    stage('Checkout code') {
      checkout scm
      if (env.BRANCH_NAME) {
        sh "git fetch --all --prune && git checkout -B ${branchName} origin/${branchName} && git reset --hard origin/${branchName}"
      } else {
        echo "No BRANCH_NAME; using currently checked out commit."
      }
    }

    stage('Build (Maven)') {
      withEnv(["PATH+MAVEN=${mvnHome}/bin"]) {
        sh "mvn -v"
        sh "mvn -U -B -DskipTests clean package"
      }
    }
	stage('Add OTel agent to context') {
	sh '''
    mkdir -p otel
    cp /opt/otel/opentelemetry-javaagent.jar otel/opentelemetry-javaagent.jar
    ls -lh otel/
	'''
}
    stage('Docker Build') {
      sh "docker build -t ${imageName}:${branchName} -f ${dockerFile} ."
    }

   stage('Push Image') {
      // Gọn sạch: dùng DOCKER_CONFIG riêng cho job, login đúng server string, push & logout
      withEnv(['DOCKER_CONFIG=.docker']) {
        sh 'mkdir -p .docker && echo "{}" > .docker/config.json'
        withCredentials([usernamePassword(credentialsId: dockerCredId, usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
          sh """
            set -e
            docker logout 192.168.137.128:18080 || true
            echo "\$REG_PASS" | docker login 192.168.137.128:18080 --username "\$REG_USER" --password-stdin
            docker push ${imageName}:${branchName}
            docker tag  ${imageName}:${branchName} ${imageName}:${branchName}-build-${buildNumber}
            docker push ${imageName}:${branchName}-build-${buildNumber}
            docker logout 192.168.137.128:18080 || true
          """
        }
      }
    }

    def imageBuild = "${imageName}:${branchName}-build-${buildNumber}"
    echo "Pushed: ${imageBuild}"

    stage('Deploy to K8s') {
      sh """#!/bin/bash -e
        echo "Deploying ${imageBuild} to ${namespace}/${k8sProjectName}"
        kubectl  -n ${namespace} get deploy ${k8sProjectName} -o name
        kubectl -n ${namespace} set image deployment/${k8sProjectName} ${k8sProjectName}=${imageBuild}
        kubectl  -n ${namespace} rollout status deployment/${k8sProjectName}
      """
    }

  } catch (e) {
    currentBuild.result = "FAILED"
    throw e
  }
}
