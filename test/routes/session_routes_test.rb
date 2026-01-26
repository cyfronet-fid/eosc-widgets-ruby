# frozen_string_literal: true

require_relative '../test_helper'

class SessionRoutesTest < Minitest::Test
  def setup
    super
    @idp = IdentityProvider.find_by!(slug: 'fid-keycloak')
  end

  def test_auth_request_phase_post
    OmniAuth.config.test_mode = true
    # Provide a dummy authenticity token to bypass OmniAuth's CSRF protection
    token = 'testtoken'
    env 'rack.session', { 'csrf' => token }
    post "/auth/#{@idp.slug}", { authenticity_token: token }
    assert last_response.redirect?, "Expected redirect but got #{last_response.status}"
    assert_match(%r{/auth/#{@idp.slug}/callback}, last_response.headers['Location'])
  ensure
    OmniAuth.config.test_mode = false
  end

  def test_auth_request_phase_get
    OmniAuth.config.test_mode = true
    get "/auth/#{@idp.slug}"
    assert last_response.redirect?, "Expected redirect but got #{last_response.status}"
    assert_match(%r{/auth/#{@idp.slug}/callback}, last_response.headers['Location'])
  ensure
    OmniAuth.config.test_mode = false
  end

  def test_auth_request_phase_invalid_provider
    get '/auth/non-existent-provider'
    assert_equal 404, last_response.status
  end

  def test_callback_success
    # Enable test mode for callback test
    OmniAuth.config.test_mode = true

    # Mock OmniAuth hash using OmniAuth::AuthHash for dot access
    omniauth_hash = OmniAuth::AuthHash.new({
                                             'provider' => @idp.slug,
                                             'uid' => '12345',
                                             'info' => {
                                               'email' => 'user@example.com',
                                               'first_name' => 'Test',
                                               'last_name' => 'User'
                                             }
                                           })

    OmniAuth.config.mock_auth[:default] = omniauth_hash

    # In test mode, we just hit the callback
    get "/auth/#{@idp.slug}/callback"

    follow_redirect!
    assert last_response.ok?

    user = User.find_by(email: 'user@example.com')
    assert user
    assert_equal 'Test', user.first_name

    uid = Uid.find_by(value: '12345', identity_provider: @idp)
    assert uid
    assert_equal user.id, uid.user_id
  ensure
    OmniAuth.config.test_mode = false
  end

  def test_logout_local
    user = User.create!(first_name: 'A', last_name: 'B', email: 'a@b.com')
    env 'rack.session', { user_id: user.id }

    get '/logout'
    assert last_response.redirect?
    assert_equal 'http://example.org/', last_response.headers['Location']
  end

  def test_logout_with_provider
    user = User.create!(first_name: 'A', last_name: 'B', email: 'a@b.com')
    env 'rack.session', { user_id: user.id, identity_provider_slug: @idp.slug }

    get '/logout'
    assert last_response.redirect?
    assert_match(%r{/auth/#{@idp.slug}/logout}, last_response.headers['Location'])
  end
end
