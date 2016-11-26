# frozen_string_literal: true

NolotiroOrg::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Raise whenever bullet finds unoptimized queries
  config.after_initialize do
    Bullet.add_whitelist type:  :counter_cache,
                         class_name: 'User',
                         association: :recently_received_reports
    Bullet.enable = true
    Bullet.raise = true
  end

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test.
  config.eager_load = false

  # Configure static asset server for tests with Cache-Control for performance.
  config.serve_static_files = true
  config.static_cache_control = 'public, max-age=3600'

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :memory_store

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  config.active_support.test_order = :random

  # for devise
  config.action_mailer.default_url_options = { host: 'localhost:3000' }

  # Set to :debug to see everything in the log.
  config.log_level = :debug
end
