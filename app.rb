# frozen_string_literal: true

require 'bundler/setup'
require 'sinatra'
require 'dotenv/load'
require 'active_record'
require 'active_support'
require 'role_model'
require 'active_support/core_ext/numeric/time'
require 'active_support/cache'
require 'yaml'
require 'erb'
require 'securerandom'
require 'pundit'
require 'friendly_id'

require_relative 'app/concerns/authentication'
require_relative 'app/helpers/application_helper'
require_relative 'app/routes/application_routes'

# Configure folders
set :root, File.dirname(__FILE__)
set :views, File.join(settings.root, 'app', 'views')
set :public_folder, File.join(settings.root, 'public')

# Logging configuration
configure do
  # Create log directory if it doesn't exist
  FileUtils.mkdir_p('log') unless File.directory?('log')

  # Server logger
  file = File.new("#{settings.root}/log/server.log", 'a+')
  file.sync = true
  use Rack::CommonLogger, file

  # Application logger for general use
  LOGGER = Logger.new("#{settings.root}/log/server.log")

  # Widgets logger (Models)
  WIDGETS_LOGGER = Logger.new("#{settings.root}/log/widgets.log")

  set :logger, LOGGER
end

# Session configuration
set :session_secret, (ENV.fetch('SESSION_SECRET') do
  raise 'SESSION_SECRET environment variable is required in production!' if settings.production?

  'a_stable_default_secret_for_development_only_1234567890_at_least_64_chars'
end)

# Disable Sinatra's built-in sessions and protection to use them manually via middleware
# This ensures we have full control over the order and configuration
set :sessions, false
set :protection, false

use Rack::Session::Cookie, {
  key: 'eosc_widgets_v3.session',
  expire_after: 24 * 3600,
  same_site: :lax,
  path: '/',
  secret: settings.session_secret,
  secure: false
}

# We exclude more protection modules that might interfere with cross-site OIDC redirects
use Rack::Protection, except: %i[session_hijacking remote_token http_origin cookie_tossing]

# Logging session ID and host for debugging
before do
  LOGGER.debug "Request Host: #{request.host}, Port: #{request.port}, Path: #{request.path}"
  if session.respond_to?(:id)
    LOGGER.debug "Current Session ID: #{session.id}"
  end
end

# Database connection (ActiveRecord) from config/database.yml (preferred) or DATABASE_URL fallback
configure do
  env = (ENV['RACK_ENV'] || settings.environment.to_s).to_s
  db_config_path = File.join(settings.root, 'config', 'database.yml')

  if File.exist?(db_config_path)
    # Parse YAML with ERB to allow env interpolation (<%= %>)
    raw = ERB.new(File.read(db_config_path)).result
    config = YAML.safe_load(raw, aliases: true) || {}
    env_config = config[env] || config[env.to_sym]

    if env_config
      # Support "url" key or full hash config
      if env_config.is_a?(Hash) && env_config['url']
        ActiveRecord::Base.establish_connection(env_config['url'])
      else
        ActiveRecord::Base.establish_connection(env_config)
      end
    else
      warn "No environment '#{env}' in config/database.yml. Falling back to DATABASE_URL."
      ActiveRecord::Base.establish_connection(ENV['DATABASE_URL']) if ENV['DATABASE_URL']
    end
  elsif ENV['DATABASE_URL'] && !ENV['DATABASE_URL'].empty?
    ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
  else
    warn 'No database configuration found (config/database.yml or DATABASE_URL). ActiveRecord will not connect.'
  end
end

# Load concerns
Dir[File.join(settings.root, 'app', 'concerns', '*.rb')].sort.each { |f| require f }

include Authentication

error Pundit::NotAuthorizedError do
  halt 403, 'You are not authorized to perform this action.'
end

# Cache store (Redis if available, otherwise MemoryStore)
configure do
  redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')
  if redis_url && !redis_url.empty?
    set :cache, ActiveSupport::Cache::RedisCacheStore.new(url: redis_url)
  else
    warn 'REDIS_URL is not set. Falling back to ActiveSupport::Cache::MemoryStore.'
    set :cache, ActiveSupport::Cache::MemoryStore.new
  end
end

# Load common models
Dir[File.join(settings.root, 'app', 'models', '*.rb')].sort.each { |f| require f }

# Load widgets
Dir[File.join(settings.root, 'lib', 'widgets', '*', 'models', '*.rb')].sort.each { |f| require f }
Dir[File.join(settings.root, 'lib', 'widgets', '*', 'routes', '*.rb')].sort.each { |f| require f }

# Load initializers
Dir[File.join(settings.root, 'config', 'initializers', '*.rb')].sort.each { |f| require f }

# Load policies
Dir[File.join(settings.root, 'app', 'policies', '*.rb')].sort.each { |f| require f }

post '/subscribe' do
  erb :greet
end
