# frozen_string_literal: true

require 'ostruct'
require_relative '../test_helper'

class FavouritesRoutesTest < Minitest::Test
  def setup
    super
    @user = User.create!(first_name: 'Test', last_name: 'User', email: 'test@example.com')
    # Mocking signed_in? and current_user is done via session
    env 'rack.session', { user_id: @user.id }
  end

  private

  def setup_token_auth
    idp = IdentityProvider.find_by!(slug: 'fid-keycloak')
    config = idp.config
    config = JSON.parse(config) if config.is_a?(String)
    config['userinfo_endpoint'] = 'https://keycloak.example.com/userinfo'
    idp.update!(config: config)

    Endpoint.find_or_create_by!(url: 'https://marketplace.example.com') do |e|
      e.name = 'Marketplace'
      e.identity_provider = idp
    end
    idp
  end

  public

  def test_index
    fav = Favourite.create!(pid: 'res_1', type: 'Endpoint', title: 'My Favourite Endpoint')
    @user.favourites << fav

    get '/favourites'
    assert last_response.ok?
    assert_includes last_response.body, 'My Favourite Endpoint'
    assert_includes last_response.body, 'res_1'
  end

  def test_add_favourite
    post '/api/favourites', {
      favourite: {
        pid: 'res_1',
        type: 'Endpoint',
        title: 'Test Endpoint',
        authors: ['Author A'],
        links: ['http://example.com'],
        best_access_right: 'open_access'
      }
    }.to_json, { 'CONTENT_TYPE' => 'application/json' }

    assert_equal 201, last_response.status
    json = JSON.parse(last_response.body)
    assert_equal 'res_1', json['pid']
    
    @user.reload
    assert_equal 1, @user.favourites.count
    assert_equal 'res_1', @user.favourites.first.pid
  end

  def test_add_favourite_html
    post '/api/favourites', {
      favourite: {
        pid: 'res_2',
        type: 'Endpoint',
        title: 'HTML Endpoint'
      }
    }

    assert last_response.redirect?
    @user.reload
    assert @user.favourites.exists?(pid: 'res_2')
  end

  def test_remove_favourite_json
    fav = Favourite.create!(pid: 'res_1', type: 'Endpoint', title: 'Test')
    @user.favourites << fav
    
    delete '/api/favourites', {
      pid: 'res_1',
      type: 'Endpoint'
    }, { 'HTTP_ACCEPT' => 'application/json' }

    assert_equal 204, last_response.status
    @user.reload
    assert_equal 0, @user.favourites.count
  end

  def test_remove_favourite_html
    fav = Favourite.create!(pid: 'res_1', type: 'Endpoint', title: 'Test')
    @user.favourites << fav
    
    delete '/api/favourites', {
      pid: 'res_1',
      type: 'Endpoint'
    }

    assert last_response.redirect?
    assert_match(%r{/favourites}, last_response.headers['Location'])
    @user.reload
    assert_equal 0, @user.favourites.count
  end

  def test_unauthorized
    env 'rack.session', {}
    post '/api/favourites', { favourite: { pid: '1', type: 't' } }.to_json
    assert_equal 401, last_response.status
  end

  def test_add_favourite_with_token
    setup_token_auth

    Net::HTTP.stub :new, Net::HTTP_Mock.new do
      env 'rack.session', {} # No session
      header 'Authorization', 'Bearer valid-token'
      header 'Origin', 'https://marketplace.example.com'
      
      post '/api/favourites', {
        favourite: {
          pid: 'res_token',
          type: 'Endpoint',
          title: 'Token Endpoint'
        }
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }
      
      assert_equal 201, last_response.status
      json = JSON.parse(last_response.body)
      assert_equal 'res_token', json['pid']
      
      user = User.find_by(email: 'token-user@example.com')
      assert user
      assert user.favourites.exists?(pid: 'res_token')
    end
  end

  def test_remove_favourite_with_token
    idp = setup_token_auth

    # Create user and favourite beforehand
    user = User.create!(first_name: 'Token', last_name: 'User', email: 'token-user@example.com')
    Uid.create!(value: 'token-user-123', identity_provider: idp, user: user)
    fav = Favourite.create!(pid: 'res_to_remove', type: 'Endpoint', title: 'To Remove')
    user.favourites << fav

    Net::HTTP.stub :new, Net::HTTP_Mock.new do
      env 'rack.session', {} # No session
      header 'Authorization', 'Bearer valid-token'
      header 'Origin', 'https://marketplace.example.com'
      header 'Accept', 'application/json'
      
      delete '/api/favourites', {
        pid: 'res_to_remove',
        type: 'Endpoint'
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }
      
      assert_equal 204, last_response.status
      
      user.reload
      assert_equal 0, user.favourites.count
    end
  end

  def test_get_favourites_with_token
    idp = setup_token_auth

    # Create user and some favourites
    user = User.create!(first_name: 'Token', last_name: 'User', email: 'token-user@example.com')
    Uid.create!(value: 'token-user-123', identity_provider: idp, user: user)
    user.favourites << Favourite.create!(pid: 'fav_1', type: 'Endpoint', title: 'Existing Fav')

    Net::HTTP.stub :new, Net::HTTP_Mock.new do
      env 'rack.session', {} # No session
      header 'Authorization', 'Bearer valid-token'
      header 'Origin', 'https://marketplace.example.com'
      
      get '/favourites'
      
      assert last_response.ok?
      assert_includes last_response.body, 'Existing Fav'
      
      user = User.find_by(email: 'token-user@example.com')
      assert_equal 'Token', user.first_name
      assert_equal 'User', user.last_name
    end
  end

  def test_auth_by_token_invalid_token
    idp = IdentityProvider.find_by!(slug: 'fid-keycloak')
    Endpoint.create!(name: 'Marketplace', url: 'https://marketplace.example.com', identity_provider: idp)

    # Mock response with 401
    mock_http = Minitest::Mock.new
    def mock_http.use_ssl=(val); end
    mock_http.expect :request, OpenStruct.new(code: '401', body: 'Unauthorized') do |req|
      req['Authorization'] == 'Bearer invalid-token'
    end

    Net::HTTP.stub :new, mock_http do
      env 'rack.session', {} # No session
      header 'Authorization', 'Bearer invalid-token'
      header 'Origin', 'https://marketplace.example.com'
      
      get '/favourites'
      # Should redirect to root because authenticate_by_token returns nil and it falls back to session auth
      assert last_response.redirect?
    end
  end

  def test_auth_by_token_missing_origin
    env 'rack.session', {} # No session
    header 'Authorization', 'Bearer some-token'
    # No Origin or Referer header
    
    get '/favourites'
    assert last_response.redirect?
  end

  def test_auth_by_token_unknown_origin
    env 'rack.session', {} # No session
    header 'Authorization', 'Bearer some-token'
    header 'Origin', 'https://unknown.com'
    
    get '/favourites'
    assert last_response.redirect?
  end
end
