pipeline {
  agent any
  stages {
    stage('build docker image') {
      steps {
        sh 'docker run -it hello-world'
      }
    }

  }
}