pipeline {
  agent any
  stages {
    stage('build docker image') {
      steps {
        sh '''

cd editor-nvidia && sudo docker build -t editor . -f  Dockerfile'''
      }
    }

  }
}