#!groovy
pipeline {
  agent none

  options {
    buildDiscarder(logRotator(numToKeepStr:'10'))
    skipDefaultCheckout()
  }

  environment {
    DB_USER = 'simba'
    DB_PASSWORD = 'simba'
    DB_NAME = 'simba_test'
    DB_VERSION = '9.4.14'
    ES_VERSION = '5.3.3'
    SELENIUM_VERSION = '3.11'
  }

  stages {
    stage("Preparing environment") {
      agent {
        label 'films'
        defaultContainer 'jnlp'
        containerTemplate {
          name 'mysql'
          image 'mysql:5.6'
          ttyEnabled true
          command 'cat'
          envVars: [
            envVar(key: 'MYSQL_ROOT_PASSWORD', value: env.MYSQL_ROOT_PASSWORD)
          ]
        }

        containerTemplate {
          name 'ruby'
          image 'ruby:2.3.1'
          ttyEnabled true
          command 'cat'
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
