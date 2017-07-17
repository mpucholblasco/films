#!/usr/bin/env groovy
pipeline {
  agent any
  stages {
    stage("Start database") {
      environment {
        MYSQL_ROOT_PASSWORD = 'mypassword'
      }

      steps {
        script {
          docker.image('mysql:5.6').withRun("-e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}") { mysql_container ->
            stage("Wait until DB will be accessible") {
              try {
                timeout(time: 5, unit: 'SECONDS') {
                  waitUntil {
                    try {
                      sh "docer exec ${mysql_container.id} mysql --user=root --password='${MYSQL_ROOT_PASSWORD}' -e 'SELECT 1'"
                      return true
                    } catch (exception) {
                      return false
                    }
                  }
                }
              } catch (timeout_exception) {
                error "Couldn't connect to DB. See previous logs for more details."
              }
            }

            docker.image('ruby:2.3.1').inside("--link ${mysql_container.id}:mysql") {
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
                  junit 'spec/reports/*.xml'
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

  post {
    failure {
      mail to: emailextrecipients([[$class: 'DevelopersRecipientProvider'],[$class: 'CulpritsRecipientProvider']]), subject: "${env.JOB_NAME} ${env.BRANCH_NAME} - Build #${env.BUILD_NUMBER} - FAILED!", body: "Check console output at ${env.BUILD_URL} to view the results."
    }
  }
}
