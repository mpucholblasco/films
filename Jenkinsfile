#!/
pipeline {
  node {
      stage("Start database") {
          docker.image('mysql:5.6').withRun("-e MYSQL_ROOT_PASSWORD=mypassword") { c ->
              echo "MySQL container ID: ${c.id}"

              // Pending: wait until MySQL server will be accessible (maybe a SELECT 1 from local?)

              docker.image('ruby:2.3.1').inside("--link ${c.id}:mysql") {
                  stage("Checkout") {
                      checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[url: 'https://github.com/mpucholblasco/films.git']]])
                  }

                  stage("Installing bundler") {
                      sh "gem install bundler --no-rdoc --no-ri"
                  }

                  stage("Installing dependencies") {
                      sh "bundle install"
                      sh "apt-get -qq update && apt-get -qq -y install nodejs"
                  }

                  stage("Configuring DB") {
                      writeFile file: "config/database.yml", text: """
  test:
    url: mysql2://root:mypassword@mysql/films_test
                      """
                  }

                  stage("Preparing DB") {
                      withEnv(["RAILS_ENV=test"]) {
                          sh "bundle exec rake db:create"
                      }
                  }

                  stage("Executing tests") {
                      withEnv(["RAILS_ENV=test"]) {
                          sh "bundle exec rake ci:setup:rspec spec"
                      }
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
