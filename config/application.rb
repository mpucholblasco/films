require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'will_paginate'
require 'will_paginate/active_record'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Films
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Europe/Madrid'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
    
    # Setting queue system
    # Steps (extracted from http://5minutenpause.com/blog/2014/11/05/comprehensive-guide-to-background-processing-of-uploads-with-activejob-and-rails-4-dot-2/):
    # 1. Add to Gemfile: gem 'delayed_job_active_record' & bundle install
    # 2. Generate DB tables: rails generate delayed_job:active_record && rake db:migrate
    # 3. Add this adapter
    config.active_job.queue_adapter = :delayed_job
    # 4. Create job: rails generate job post_process_upload
    # 5. Change job code
    # 6. Start jobs: https://github.com/collectiveidea/delayed_job#running-jobs
  end
end
