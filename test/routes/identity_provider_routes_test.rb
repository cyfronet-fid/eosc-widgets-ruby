# frozen_string_literal: true

require 'ostruct'
require_relative '../test_helper'

class IdentityProviderRoutesTest < Minitest::Test
  def setup
    super
    @admin = User.create!(first_name: 'Admin', last_name: 'User', email: 'admin@example.com', roles_mask: 1)
    env 'rack.session', { user_id: @admin.id }
  end

  def test_index
    IdentityProvider.create!(name: 'Test IDP', url: 'https://example.com')
    get '/identity_providers'
    assert last_response.ok?
    assert_includes last_response.body, 'Test IDP'
  end

  def test_index_with_token
    idp = IdentityProvider.find_by!(slug: 'fid-keycloak')
    config = idp.config
    config = JSON.parse(config) if config.is_a?(String)
    config['userinfo_endpoint'] = 'https://keycloak.example.com/userinfo'
    idp.update!(config: config)

    Endpoint.create!(name: 'Marketplace', url: 'https://marketplace.example.com', identity_provider: idp)

    mock_http = Net::HTTP_Mock.new(response_body: {
      sub: 'admin-123',
      email: 'admin@example.com',
      name: 'Admin User'
    }.to_json)

    Net::HTTP.stub :new, mock_http do
      env 'rack.session', {} # No session
      header 'Authorization', 'Bearer admin-token'
      header 'Origin', 'https://marketplace.example.com'
      
      get '/identity_providers'
      assert_equal 200, last_response.status, "Response body: #{last_response.body}"
      assert last_response.ok?
      assert_includes last_response.body, 'Identity Providers'
    end
  end

  def test_create
    post '/identity_providers', {
      identity_provider: {
        name: 'New IDP',
        url: 'https://new.example.com',
        config: '{"client_id": "123"}'
      }
    }
    follow_redirect!
    assert last_response.ok?
    assert_includes last_response.body, 'New IDP'

    idp = IdentityProvider.find_by(name: 'New IDP')
    assert_equal '123', idp.config['client_id']
  end

  def test_update
    idp = IdentityProvider.create!(name: 'Old Name', url: 'https://example.com')
    put "/identity_providers/#{idp.slug}", {
      identity_provider: { name: 'Updated Name' }
    }
    follow_redirect!
    assert last_response.ok?
    assert_includes last_response.body, 'Updated Name'
  end
end
