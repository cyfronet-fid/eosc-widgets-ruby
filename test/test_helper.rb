# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'minitest/mock'
require 'rack/test'
require 'minitest/reporters'

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]

# Pre-load database and models to ensure OmniAuth can register providers during app boot
require 'active_record'
require 'erb'
require 'yaml'
require 'friendly_id'
require 'role_model'
db_config = YAML.safe_load(ERB.new(File.read(File.expand_path('../config/database.yml', __dir__))).result,
                           aliases: true)['test']
ActiveRecord::Base.establish_connection(db_config)

# Load models needed for OmniAuth initialization
require_relative '../app/models/application_record'
require_relative '../app/models/identity_provider'

if ActiveRecord::Base.connection.table_exists?('identity_providers')
  IdentityProvider.find_or_create_by!(slug: 'fid-keycloak') do |idp|
    idp.name = 'FID Keycloak'
    idp.url = 'https://keycloak.example.com'
    idp.config = { client_id: 'test' }.to_json
  end
end

require File.expand_path('../app.rb', __dir__)

module Minitest
  class Test
    include Rack::Test::Methods

    def app
      Sinatra::Application
    end

    def setup
      # Clean database before each test, respecting foreign key constraints
      # Order matters: Uid depends on User and IdentityProvider, Endpoint depends on IdentityProvider
      Uid.delete_all
      Endpoint.delete_all
      # Clear the join table first or use dependent: :destroy
      ActiveRecord::Base.connection.execute("DELETE FROM users_favourites")
      Favourite.delete_all
      User.delete_all
      # We keep the test IDP used by OmniAuth registration
      IdentityProvider.where.not(slug: 'fid-keycloak').delete_all
    end
  end
end

# Helper class to simplify Net::HTTP mocking
class Net::HTTP_Mock
  attr_reader :last_request

  def initialize(response_body: nil, response_code: '200')
    @response_body = response_body
    @response_code = response_code
  end

  def use_ssl=(val); end

  def request(req)
    @last_request = req
    mock_response = Minitest::Mock.new
    mock_response.expect :code, @response_code
    mock_response.expect :body, @response_body || {
      sub: 'token-user-123',
      email: 'token-user@example.com',
      name: 'Token User'
    }.to_json
    mock_response
  end
end
