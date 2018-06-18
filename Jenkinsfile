#!groovy
pipeline {
  agent none

  options {
    buildDiscarder(logRotator(numToKeepStr:'10'))
    skipDefaultCheckout()
  }

  environment {
    MYSQL_ROOT_PASSWORD = 'mypassword'
  }

  stages {
    stage("Preparing environment") {
      agent {
        kubernetes {
          label 'films'
          defaultContainer 'jnlp'
          yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: mysql
    image: mysql:5.6
    env:
      - name: MYSQL_ROOT_PASSWORD
        value: "${env.MYSQL_ROOT_PASSWORD}"
  - name: ruby
    image: ruby:2.3.1
    command:
    - cat
    tty: true
"""
        }
      }

      steps {
        container('ruby') {
          script {
            stage("Checkout") {
              checkout scm
            }

            stage("Installing bundler") {
              sh "gem install bundler --no-rdoc --no-ri"
            }

            stage("Installing dependencies") {
              sh "bundle install"
              sh "apt-get -qq update && apt-get -qq -y install nodejs"
            }

            withEnv(["DATABASE_URL=mysql2://root:${MYSQL_ROOT_PASSWORD}@mysql/films_test", "RAILS_ENV=test"]) {
              stage("Preparing DB") {
                sh "bundle exec rake db:create"
              }

              stage("Executing tests") {
                sh "bundle exec rake ci:setup:rspec spec"

                // Publish spec results
                junit 'spec/reports/*.xml'

                // Publish rcov results (requires HTML Publisher plugin)
                publishHTML (target: [
                  allowMissing: false,
                  alwaysLinkToLastBuild: false,
                  keepAll: true,
                  reportDir: 'coverage',
                  reportFiles: 'index.html',
                  reportName: "RCov Report"
                ])
              }

              stage("Security scan") {
                sh "bundle exec brakeman -o brakeman-output.tabs --no-progress --separate-models"
                // Requires Brakeman Plugin
                publishBrakeman 'brakeman-output.tabs'
              }
            }
          }
        }
      }
    }
  }
}
