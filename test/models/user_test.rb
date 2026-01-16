# frozen_string_literal: true

require_relative '../test_helper'

class UserTest < Minitest::Test
  def test_user_creation
    user = User.new(
      first_name: 'John',
      last_name: 'Doe',
      email: 'john.doe@example.com'
    )
    assert user.save
    assert_equal 'John', user.first_name
  end

  def test_user_validation
    user = User.new
    refute user.valid?
    assert_includes user.errors[:first_name], "can't be blank"
    assert_includes user.errors[:last_name], "can't be blank"
    assert_includes user.errors[:email], "can't be blank"
  end

  def test_user_email_uniqueness
    User.create!(first_name: 'A', last_name: 'B', email: 'test@example.com')
    user = User.new(first_name: 'C', last_name: 'D', email: 'test@example.com')
    refute user.save
    assert_includes user.errors[:email], 'has already been taken'
  end
end
