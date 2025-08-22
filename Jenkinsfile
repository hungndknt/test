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
    def branchName  = env.BRANCH_NAME ?: "main"

    // LẤY MAVEN TỪ 'Manage Jenkins > Tools'
    def mvnHome = tool 'apache-maven-3.9.11'   // <-- đúng tên bạn đã cấu hình
    // (tuỳ chọn) nếu JDK cũng là tool
    // def jdkHome = tool 'jdk17'; withEnv(["JAVA_HOME=${jdkHome}", "PATH+JAVA=${jdkHome}/bin"])

    stage('Workspace Clearing') { cleanWs() }

    stage('Checkout code') {
      checkout scm
      if (env.BRANCH_NAME) {
        sh "git fetch --all --prune && git checkout -B ${branchName} origin/${branchName} && git reset --hard origin/${branchName}"
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
        docker push ${imageName}:${branchName}
        docker tag  ${imageName}:${branchName} ${imageName}:${branchName}-build-${buildNumber}
        docker push ${imageName}:${branchName}-build-${buildNumber}
      """
    }

    echo "Pushed: ${imageName}:${branchName}-build-${buildNumber}"
    stage('Deploy to K8s') {
    sh """#!/bin/bash -e
    echo "Deploying ${imageBuild} to ${namespace}/${k8sProjectName}"
    kubectl --kubeconfig ${kubeconfig} -n ${namespace} get deploy ${k8sProjectName} -o name
    kubectl --kubeconfig ${kubeconfig} -n ${namespace} \
      set image deployment/${k8sProjectName} ${k8sProjectName}=${imageBuild}

    kubectl --kubeconfig ${kubeconfig} -n ${namespace} \
      rollout status deployment/${k8sProjectName}
  } catch (e) {
    currentBuild.result = "FAILED"
    throw e
  }
}
