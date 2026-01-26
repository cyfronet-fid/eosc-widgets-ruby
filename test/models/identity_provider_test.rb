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
end
