# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

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

  def token_endpoint
    # Ensure config is a Hash
    cfg = config.is_a?(String) ? JSON.parse(config) : config
    return nil unless cfg.is_a?(Hash)

    cfg['token_endpoint'] || "#{cfg['issuer']}/protocol/openid-connect/token"
  end

  def exchange_token(subject_token, audience: nil)
    # Ensure config is a Hash
    cfg = config.is_a?(String) ? JSON.parse(config) : config
    return nil unless cfg.is_a?(Hash)

    url = token_endpoint
    return nil unless url

    uri = URI.parse(url)

    params = {
      'grant_type' => 'urn:ietf:params:oauth:grant-type:token-exchange',
      'subject_token' => subject_token,
      'subject_token_type' => 'urn:ietf:params:oauth:token-type:access_token',
      'client_id' => cfg['client_id'],
      'client_secret' => cfg['client_secret']
    }
    params['audience'] = audience if audience && !audience.to_s.empty?

    WIDGETS_LOGGER.info "Exchanging token for IDP: #{slug}, audience: #{audience}" if defined?(WIDGETS_LOGGER)

    response = Net::HTTP.post_form(uri, params)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      WIDGETS_LOGGER.error "Keycloak Token Exchange failed for #{slug}: #{response.code} - #{response.body}" if defined?(WIDGETS_LOGGER)
      nil
    end
  rescue StandardError => e
    WIDGETS_LOGGER.error "Keycloak Token Exchange error for #{slug}: #{e.message}" if defined?(WIDGETS_LOGGER)
    nil
  end

  private

  def log_change
    WIDGETS_LOGGER.info "IdentityProvider change: #{inspect}" if defined?(WIDGETS_LOGGER)
  end
end
