# frozen_string_literal: true

require_relative '../test_helper'

class ProfileRoutesTest < Minitest::Test
  def setup
    super
    @user = User.create!(first_name: 'John', last_name: 'Doe', email: 'john@example.com')
  end

  def test_profile_unauthorized
    get '/profile'
    assert last_response.redirect?
    assert_match(%r{/}, last_response.headers['Location'])
  end

  def test_profile_authorized
    env 'rack.session', { 
      user_id: @user.id, 
      identity_provider_slug: 'test-idp',
      auth: {
        'test-idp' => { uid: 'user-123', access_token: 'secret-token' }
      }
    }
    
    get '/profile'
    
    assert last_response.ok?
    assert_includes last_response.body, 'User Profile'
    assert_includes last_response.body, 'user-123'
    assert_includes last_response.body, 'secret-token'
    assert_includes last_response.body, 'John Doe'
    assert_includes last_response.body, 'john@example.com'
    assert_includes last_response.body, 'test-idp'
    
    # Check for new UI elements (with provider suffix)
    assert_includes last_response.body, 'id="accessToken-test-idp"'
    assert_includes last_response.body, 'type="password"'
    assert_includes last_response.body, 'id="toggleToken-test-idp"'
    assert_includes last_response.body, 'id="copyToken-test-idp"'
    
    # Check for color propagation hidden input
    assert_includes last_response.body, 'data-color-target="color"'
  end

  def test_callback_sets_session_data
    auth_hash = OmniAuth::AuthHash.new({
      uid: 'uid-from-idp',
      info: {
        email: 'idp-user@example.com',
        first_name: 'IDP',
        last_name: 'User'
      },
      credentials: {
        token: 'idp-access-token'
      }
    })

    # Create IDP to match the provider in URL
    IdentityProvider.create!(slug: 'keycloak', name: 'Keycloak', url: 'https://keycloak.example.com')

    get '/auth/keycloak/callback', {}, { 'omniauth.auth' => auth_hash }

    assert_equal 'uid-from-idp', last_request.env['rack.session'][:auth]['keycloak'][:uid]
    assert_equal 'idp-access-token', last_request.env['rack.session'][:auth]['keycloak'][:access_token]
  end

  def test_profile_with_string_keys_in_session
    env 'rack.session', { 
      'user_id' => @user.id, 
      'auth' => {
        'test-idp' => { 'uid' => 'string-uid', 'access_token' => 'string-token' }
      }
    }
    
    get '/profile'
    
    assert last_response.ok?
    assert_includes last_response.body, 'string-uid'
    assert_includes last_response.body, 'string-token'
  end
end
