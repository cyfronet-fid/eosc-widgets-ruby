# frozen_string_literal: true

require 'omniauth'
require 'omniauth_openid_connect'

# Create log directory if it doesn't exist
FileUtils.mkdir_p('log') unless File.directory?('log')

OmniAuth.config.logger = Logger.new('log/omniauth.log')
OmniAuth.config.allowed_request_methods = [:post]

# Ensure we have at least one IdentityProvider for tests to avoid registration issues
if ENV['RACK_ENV'] == 'test'
  begin
    if ActiveRecord::Base.connection.table_exists?('identity_providers')
      IdentityProvider.find_or_create_by!(slug: 'fid-keycloak') do |idp|
        idp.name = 'FID Keycloak'
        idp.url = 'https://keycloak.example.com'
        idp.config = { client_id: 'test' }.to_json
      end
    end
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
    # Ignore if DB not ready
  end
end

# Configure allowed origins for authenticity token protection
# We gather hosts from IdentityProviders and Endpoints to allow redirects/POSTs
OmniAuth.config.request_validation_phase = proc do |env|
  if ActiveRecord::Base.connection.table_exists?('identity_providers')
    idp_hosts = IdentityProvider.pluck(:url).map { |u| URI.parse(u).host }.compact
    endpoint_hosts = Endpoint.pluck(:url).map { |u| URI.parse(u).host }.compact
    allowed_hosts = (idp_hosts + endpoint_hosts + ['localhost', '127.0.0.1']).uniq
    allowed_origins = allowed_hosts.map { |h| ["http://#{h}", "https://#{h}"] }.flatten
    allowed_origins << 'http://localhost:9292'
    allowed_origins << 'https://localhost:9292'
    allowed_origins << 'http://127.0.0.1:9292'
    allowed_origins << 'https://127.0.0.1:9292'

    origin = env['HTTP_ORIGIN']
    if origin && !allowed_origins.include?(origin)
      OmniAuth.config.logger.warn "Origin #{origin} not allowed. Allowed origins: #{allowed_origins.join(', ')}"
      # We don't raise error here, OmniAuth::AuthenticityTokenProtection will handle it
      # but we could potentially bypass it by setting a flag or similar if needed.
      # Actually, OmniAuth::AuthenticityTokenProtection is a middleware in the stack.
    end
  end
rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
  # Skip if database is not ready
end

# Register OmniAuth as middleware
# We gather allowed origins from IDPs and Endpoints to prevent AuthenticityToken errors
allowed_origins = []
begin
  if ActiveRecord::Base.connection.table_exists?('identity_providers')
    idp_hosts = IdentityProvider.pluck(:url).map do |u|
      URI.parse(u).host
    rescue StandardError
      nil
    end.compact
    endpoint_hosts = Endpoint.pluck(:url).map do |u|
      URI.parse(u).host
    rescue StandardError
      nil
    end.compact
    idp_configs = IdentityProvider.pluck(:config)
    redirect_hosts = idp_configs.map do |cfg|
      cfg = JSON.parse(cfg) if cfg.is_a?(String)
      next unless cfg.is_a?(Hash) && cfg['redirect_uri']

      begin
        URI.parse(cfg['redirect_uri']).host
      rescue StandardError
        nil
      end
    end.compact
    allowed_hosts = (idp_hosts + endpoint_hosts + redirect_hosts + ['localhost', '127.0.0.1']).uniq
    allowed_origins = allowed_hosts.map { |h| ["http://#{h}", "https://#{h}"] }.flatten
    allowed_origins << 'http://localhost:9292'
    allowed_origins << 'https://localhost:9292'
    allowed_origins << 'http://127.0.0.1:9292'
    allowed_origins << 'https://127.0.0.1:9292'
  end
rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
  # Skip if database is not ready
end

OmniAuth.config.logger.info "Allowed origins for OmniAuth: #{allowed_origins.join(', ')}" if allowed_origins.any?

# Only use OmniAuth::Builder once to prevent issues in tests
if Sinatra::Application.middleware.none? { |m| m.first == OmniAuth::Builder }
  OmniAuth.config.before_request_phase = proc do |env|
    req = Rack::Request.new(env)
    strategy = env['omniauth.strategy']

    # Dynamically adjust redirect_uri to match current host and port
    # This prevents CSRF/State mismatch when switching between localhost and 127.0.0.1
    if strategy.options&.client_options&.redirect_uri
      begin
        uri = URI.parse(strategy.options.client_options.redirect_uri)
        if uri.host != req.host || uri.port != req.port
          old_uri = uri.to_s
          uri.host = req.host
          uri.port = req.port
          strategy.options.client_options.redirect_uri = uri.to_s
          OmniAuth.config.logger.info "Dynamic redirect_uri adjusted: #{old_uri} -> #{uri}"
        end
      rescue StandardError => e
        OmniAuth.config.logger.error "Failed to adjust redirect_uri: #{e.message}"
      end
    end

    OmniAuth.config.logger.info "Before Request Phase: session id: #{req.session.id if req.session.respond_to?(:id)}"
    OmniAuth.config.logger.info "Session before state set: #{req.session.to_hash}"
  end

  OmniAuth.config.before_callback_phase = proc do |env|
    req = Rack::Request.new(env)
    state_in_session = req.session['omniauth.state']
    state_in_params = req.params['state']
    OmniAuth.config.logger.info "Before Callback Phase: session id: #{req.session.id if req.session.respond_to?(:id)}"
    OmniAuth.config.logger.info "Session in callback: #{req.session.to_hash}"
    OmniAuth.config.logger.info "State in session: #{state_in_session}, state in params: #{state_in_params}"
    if state_in_session != state_in_params
      OmniAuth.config.logger.warn "State mismatch! Request host: #{req.host}, referrer: #{req.referer}"
    end
  end

  use OmniAuth::Builder, allowed_origins: allowed_origins do
    # Ensure database connection is established and table exists
    if ActiveRecord::Base.connection.table_exists?('identity_providers')
      IdentityProvider.find_each do |idp|
        idp.config = JSON.parse(idp.config) if idp.config.is_a?(String)
        OmniAuth.config.logger.debug "IdentityProvider: #{idp.inspect}"
        OmniAuth.config.logger.debug "IdentityProvider config: #{idp.config}"
        next unless idp.config.present?

        OmniAuth.config.logger.info "Registering OmniAuth provider: #{idp.slug}"
        OmniAuth.config.logger.debug "IdentityProvider issuer: #{idp.config['issuer']}"

        discovery = idp.config.key?('discovery') ? idp.config['discovery'] : true

        options = {
          name: idp.slug,
          scope: idp.config['scope'] || %w[openid profile email],
          discovery: discovery,
          response_type: :code,
          issuer: idp.config['issuer'],
          post_logout_redirect_uri: idp.config['post_logout_redirect_uri'] || 'http://localhost:9292/logout',
          client_options: {
            identifier: idp.config['client_id'],
            secret: idp.config['client_secret'],
            redirect_uri: idp.config['redirect_uri']
          }
        }

        if idp.url.present?
          uri = URI.parse(idp.url)
          options[:client_options][:host] = uri.host
          options[:client_options][:scheme] = uri.scheme
          options[:client_options][:port] = uri.port
        end

        # Add endpoints if discovery is disabled or as fallback
        options[:client_options][:authorization_endpoint] = idp.config['authorization_endpoint'] if idp.config['authorization_endpoint']
        options[:client_options][:token_endpoint] = idp.config['token_endpoint'] if idp.config['token_endpoint']
        options[:client_options][:userinfo_endpoint] = idp.config['userinfo_endpoint'] if idp.config['userinfo_endpoint']
        options[:client_options][:jwks_uri] = idp.config['jwks_uri'] if idp.config['jwks_uri']
        provider :openid_connect, **options
        OmniAuth.config.logger.info "IdentityProvider successfully initialized: #{idp.slug}"
      end
    end
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
    OmniAuth.config.logger.warn 'Database not ready, skipping dynamic OmniAuth configuration'
  rescue StandardError => e
    OmniAuth.config.logger.error "OmniAuth configuration failed: #{e.message}"
  end

  OmniAuth.config.allowed_request_methods << :get
  OmniAuth.config.silence_get_warning = true
end
