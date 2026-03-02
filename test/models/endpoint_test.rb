# frozen_string_literal: true

require_relative '../test_helper'

class EndpointTest < Minitest::Test
  def setup
    super
    @idp = IdentityProvider.create!(
      name: 'IDP for Endpoint',
      url: 'https://idp.example.com',
      config: {
        client_id: 'client123',
        client_secret: 'secret123',
        token_endpoint: 'https://keycloak.example.com/token'
      }.to_json
    )
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

  def test_exchange_token
    endpoint = Endpoint.create!(
      name: 'Test Endpoint',
      url: 'https://endpoint.example.com',
      abbreviation: 'WIDGET_A',
      identity_provider: @idp
    )

    response_body = { 'access_token' => 'widget-token' }.to_json
    response = Minitest::Mock.new
    response.expect :is_a?, true, [Net::HTTPSuccess]
    response.expect :body, response_body

    Net::HTTP.stub :post_form, response do
      result = endpoint.exchange_token('subject-token')
      assert_equal 'widget-token', result['access_token']
    end
  end
end
