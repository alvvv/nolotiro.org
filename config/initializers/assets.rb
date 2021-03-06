# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

unless Rails.env.test? || Rails.env.development?
  # Compress JavaScripts and CSS.
  Rails.application.config.assets.js_compressor = :uglifier
  # Rails.application.config.assets.js_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  Rails.application.config.assets.compile = false

  # Generate digests for assets URLs.
  Rails.application.config.assets.digest = true

  # Add additional assets to the asset load path
  # Rails.application.config.assets.paths << Emoji.images_path

  # Version of your assets, change this if you want to expire all your assets.
  Rails.application.config.assets.version = '1.0'

  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in app/assets folder are
  # already added.
  # Rails.application.config.assets.precompile += %w( search.js )
end
