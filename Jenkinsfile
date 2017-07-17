#!/usr/bin/env groovy
pipeline {
  node {
    mysql_root_password="mypassword"
    stage("Start database") {
      docker.image('mysql:5.6').withRun("-e MYSQL_ROOT_PASSWORD=${mysql_root_password}") { mysql_container ->
        stage("Wait until DB will be accessible") {
          try {
            timeout(time: 120, unit: 'SECONDS') {
              waitUntil {
                try {
                  sh "docker exec ${mysql_container.id} mysql --user=root --password='${mysql_root_password}' -e 'SELECT 1'"
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

          withEnv(["DATABASE_URL=mysql2://root:${mysql_root_password}@mysql/films_test", "RAILS_ENV=test"]) {
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
