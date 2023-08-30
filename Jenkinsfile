pipeline {
  agent any
  stages {
    stage('build docker image') {
      steps {
        sh '''

cd editor-nvidia && docker build -t editor . -f  Dockerfile'''
      }
    }

  }
}