# frozen_string_literal: true

require_relative '../test_helper'

class EndpointRoutesTest < Minitest::Test
  def setup
    super
    @admin = User.create!(first_name: 'Admin', last_name: 'User', email: 'admin@example.com', roles_mask: 1)
    @idp = IdentityProvider.create!(name: 'IDP', url: 'https://idp.com')
    env 'rack.session', { user_id: @admin.id }
  end

  def test_index
    Endpoint.create!(name: 'Test Endpoint', url: 'https://s.com', identity_provider: @idp)
    get '/endpoints'
    assert last_response.ok?
    assert_includes last_response.body, 'Test Endpoint'
  end

  def test_create
    post '/endpoints', {
      endpoint: {
        name: 'New Endpoint',
        url: 'https://new.s.com',
        identity_provider_id: @idp.id
      }
    }
    follow_redirect!
    assert last_response.ok?
    assert_includes last_response.body, 'New Endpoint'
  end
end
