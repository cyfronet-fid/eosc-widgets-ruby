# frozen_string_literal: true

require_relative '../test_helper'

class EndpointTest < Minitest::Test
  def setup
    super
    @idp = IdentityProvider.create!(name: 'IDP for Endpoint', url: 'https://idp.example.com')
  end

  def test_endpoint_creation
    endpoint = Endpoint.new(
      name: 'Test Endpoint',
      url: 'https://endpoint.example.com',
      identity_provider: @idp
    )
    assert endpoint.save
    assert_equal 'test-endpoint', endpoint.slug
  end

  def test_endpoint_validation
    endpoint = Endpoint.new
    refute endpoint.valid?
    assert_includes endpoint.errors[:name], "can't be blank"
    assert_includes endpoint.errors[:url], "can't be blank"
  end
end
