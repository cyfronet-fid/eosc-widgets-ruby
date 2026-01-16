# frozen_string_literal: true

require_relative '../test_helper'

class ApplicationRoutesTest < Minitest::Test
  def test_root_path
    get '/'
    assert last_response.ok?
    assert_includes last_response.body, 'EOSC Widgets'
  end

  def test_unauthorized_access
    # IdentityProvider index requires admin
    get '/identity_providers'
    assert_equal 403, last_response.status
    assert_includes last_response.body, 'You are not authorized'
  end

  def test_authorized_access
    # Mock admin login
    admin = User.create!(first_name: 'Admin', last_name: 'User', email: 'admin@example.com', roles_mask: 1)

    env 'rack.session', { user_id: admin.id }
    get '/identity_providers'
    assert last_response.ok?
    assert_includes last_response.body, 'Identity Providers'
  end
end
