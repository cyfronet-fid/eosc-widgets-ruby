# frozen_string_literal: true

class Uid < ApplicationRecord
  belongs_to :user
  belongs_to :identity_provider

  validates :value, presence: true
end
