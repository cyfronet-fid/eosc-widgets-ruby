# frozen_string_literal: true

class Favourite < ApplicationRecord
  self.inheritance_column = nil
  has_and_belongs_to_many :users, join_table: :users_favourites

  validates :pid, :type, presence: true
  validates :pid, uniqueness: { scope: :type }
end
