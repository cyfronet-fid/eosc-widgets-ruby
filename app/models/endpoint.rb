# frozen_string_literal: true

class Endpoint < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  # Shared endpoint model for all widgets
  belongs_to :identity_provider

  validates :name, :url, presence: true

  after_save :log_change
  after_destroy :log_change

  private

  def log_change
    WIDGETS_LOGGER.info "Endpoint change: #{inspect}" if defined?(WIDGETS_LOGGER)
  end
end
