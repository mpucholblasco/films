source 'https://rubygems.org'

gem 'rake', '< 11.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.10'
# Use mysql as the database for Active Record
gem 'mysql2', '~> 0.3.18'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# For pagination purposes
gem 'will_paginate', '~> 3.0.6'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# i18n-js
# You only need this RC version constraint during the development of `3.0.0`, once stable version is released you can remove `rc8` suffix
# `3.0.0.rc8` is the latest version of released RC version when this entry is changed, you might want to change it later
gem "i18n-js", ">= 3.0.0.rc8"

# Queue gem system
gem 'delayed_job_active_record'
gem 'daemons'

# Filesystem information
gem 'sys-filesystem'

# Fileutils
gem 'fileutils'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

group :development, :test do
  gem 'rspec-rails', '~> 3.5'
  gem 'capybara', '~> 2.5'
end

group :test do
  gem 'faker', '~> 1.6.1'
  gem 'ci_reporter'
  gem 'ci_reporter_rspec'

  # Static analysis (vulnerabilities)
  gem 'brakeman', :require => false

  # Coverage
  gem 'simplecov', :require => false
  gem 'simplecov-rcov', :require => false
end
