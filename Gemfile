# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '4.0.0'

gem 'irb'
gem 'rake'
gem 'sinatra'

# Server
gem 'kamal'
gem 'puma'
gem 'puma_worker_killer'
gem 'timeout', '~>0.4'
gem 'zeitwerk'

# Authentication
gem 'friendly_id'
gem 'omniauth_openid_connect'
gem 'pundit'

# Environment variables
gem 'dotenv'

# Database + ORM
gem 'activerecord'
gem 'activesupport'
gem 'pg'
gem 'role_model'
gem 'sinatra-activerecord'
gem 'sprockets', '~> 4.0'
gem 'sprockets-helpers'
gem 'sassc'

# API
gem 'active_model_serializers'
gem 'rack-test'

# Cache (Redis)
gem 'connection_pool', '~> 2.2'
gem 'redis', '>= 4.0.1'
gem 'sidekiq'

group :development, :test do
  gem 'brakeman'
  gem 'byebug'
  gem 'haml_lint', require: false
  gem 'minitest'
  gem 'minitest-mock'
  gem 'minitest-reporters'
  gem 'overcommit', require: false
  gem 'prettier', require: false
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-nav'
  gem 'rack-unreloader'
  gem 'rubocop'
end

gem "rackup", "~> 2.3"
