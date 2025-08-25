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

    stage('Docker Build') {
      sh "docker build -t ${imageName}:${branchName} -f ${dockerFile} ."
    }

    stage('Push Image') {
      sh """
        docker pull busybox:latest
        docker tag busybox:latest 192.168.137.128:18080/ci/pipeline-canpush:build-${BUILD_NUMBER}
        docker push 192.168.137.128:18080/ci/pipeline-canpush:build-${BUILD_NUMBER}
        docker push ${imageName}:${branchName}
        docker tag  ${imageName}:${branchName} ${imageName}:${branchName}-build-${buildNumber}
        docker push ${imageName}:${branchName}-build-${buildNumber}
      """
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
