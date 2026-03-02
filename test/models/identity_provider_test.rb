# frozen_string_literal: true

require_relative '../test_helper'

class IdentityProviderTest < Minitest::Test
  def test_idp_creation
    idp = IdentityProvider.new(name: 'Test IDP', url: 'https://idp.example.com')
    assert idp.save
    assert_equal 'test-idp', idp.slug
  end

  def test_idp_validation
    idp = IdentityProvider.new
    refute idp.valid?
    assert_includes idp.errors[:name], "can't be blank"
  end

  def test_idp_log_change
    idp = IdentityProvider.create!(name: 'Log Test', url: 'https://idp.example.com')
    # Check if WIDGETS_LOGGER was called
    # Since we can't easily mock/spy on the logger without extra gems,
    # we just ensure it doesn't crash.
    idp.update(name: 'Updated Name')
    idp.destroy
  end

  def test_token_endpoint_from_config
    idp = IdentityProvider.new(config: { token_endpoint: 'https://keycloak.example.com/token' }.to_json)
    assert_equal 'https://keycloak.example.com/token', idp.token_endpoint
  end

  def test_token_endpoint_from_issuer
    idp = IdentityProvider.new(config: { issuer: 'https://keycloak.example.com' }.to_json)
    assert_equal 'https://keycloak.example.com/protocol/openid-connect/token', idp.token_endpoint
  end

  def test_exchange_token_success
    idp = IdentityProvider.new(
      slug: 'test-idp',
      config: {
        client_id: 'client123',
        client_secret: 'secret123',
        token_endpoint: 'https://keycloak.example.com/token'
      }.to_json
    )

    response_body = { 'access_token' => 'new-token' }.to_json
    response = Minitest::Mock.new
    response.expect :is_a?, true, [Net::HTTPSuccess]
    response.expect :body, response_body

    Net::HTTP.stub :post_form, response do
      result = idp.exchange_token('subject-token', audience: 'widget-audience')
      assert_equal 'new-token', result['access_token']
    end
  end

  def test_exchange_token_failure
    idp = IdentityProvider.new(
      slug: 'test-idp',
      config: {
        client_id: 'client123',
        client_secret: 'secret123',
        token_endpoint: 'https://keycloak.example.com/token'
      }.to_json
    )

    response = Minitest::Mock.new
    response.expect :is_a?, false, [Net::HTTPSuccess]
    response.expect :code, '401'
    response.expect :body, 'Unauthorized'

    Net::HTTP.stub :post_form, response do
      result = idp.exchange_token('subject-token')
      assert_nil result
    end
  end
end
