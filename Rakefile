# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require 'ci/reporter/rake/rspec'
# Make sure we setup ci_reporter before executing our RSpec examples
task :spec => 'ci:setup:rspec'

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks
