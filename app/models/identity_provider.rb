# frozen_string_literal: true

class IdentityProvider < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  # Shared identity provider model for all widgets
  has_many :endpoints, dependent: :destroy
  has_many :uids, dependent: :destroy
  has_many :users, through: :uids

  validates :name, presence: true

  after_save :log_change
  after_destroy :log_change

  private

  def log_change
    WIDGETS_LOGGER.info "IdentityProvider change: #{inspect}" if defined?(WIDGETS_LOGGER)
  end
end
