# frozen_string_literal: true

class User < ApplicationRecord
  include RoleModel

  roles :admin

  has_many :uids, dependent: :destroy
  has_many :identity_providers, through: :uids
  has_and_belongs_to_many :favourites, join_table: :users_favourites

  validates :first_name, :last_name, :email, presence: true
  validates :email, uniqueness: true
end
