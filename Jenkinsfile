#!groovy
pipeline {
  agent any

  options {
    buildDiscarder(logRotator(numToKeepStr:'10'))
    skipDefaultCheckout()
  }

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
                timeout(time: 120, unit: 'SECONDS') {
                  waitUntil {
                    try {
                      sh "docker exec ${mysql_container.id} mysql --user=root --password='${MYSQL_ROOT_PASSWORD}' -e 'SELECT 1'"
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

  post {
    success {
      try {
        slackSend color: '#00FF00',
          message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
      }catch(exc) {}
    }

    failure {
      emailext subject: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
        body: """<p>FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]':</p>
        <p>Check console output at "<a href="${env.BUILD_URL}">${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>"</p>""",
        recipientProviders: [[$class: 'DevelopersRecipientProvider']]

      try {
        slackSend color: '#FF0000',
          message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
      }catch(exc) {}
    }
  }
}
