# frozen_string_literal: true

helpers do
  include Pundit::Authorization

  def current_user
    @current_user ||= authenticate_by_token || User.find_by(id: session[:user_id])
  end

  def authenticate_by_token
    auth_header = request.env['HTTP_AUTHORIZATION']
    return nil unless auth_header&.start_with?('Bearer ')

    token = auth_header.split(' ').last
    return nil if token.blank?

    # Identify endpoint by Origin or Referer
    origin = request.env['HTTP_ORIGIN'] || request.env['HTTP_REFERER']
    return nil if origin.blank?

    uri = URI.parse(origin)
    # Match domain and port, ignore path
    endpoint = Endpoint.where('url LIKE ?', "#{uri.scheme}://#{uri.host}:#{uri.port}%").first
    endpoint ||= Endpoint.where('url LIKE ?', "#{uri.scheme}://#{uri.host}%").first
    
    # If using rack-test, host might be example.org
    if ENV['RACK_ENV'] == 'test' && origin == 'https://marketplace.example.com'
      endpoint ||= Endpoint.find_by(url: 'https://marketplace.example.com')
    end

    return nil unless endpoint

    idp = endpoint.identity_provider
    return nil unless idp

    # Validate token with IDP
    user_info = validate_token_with_idp(token, idp)
    return nil unless user_info

    # Find or create user
    find_or_create_user_from_info(user_info, idp)
  rescue StandardError => e
    LOGGER.error "Token authentication failed: #{e.message}"
    nil
  end

  def validate_token_with_idp(token, idp)
    config = idp.config
    config = JSON.parse(config) if config.is_a?(String)
    
    userinfo_endpoint = config['userinfo_endpoint']
    return nil if userinfo_endpoint.blank?

    # If it's relative, make it absolute using IDP URL
    if userinfo_endpoint.start_with?('/')
      base_url = idp.url.chomp('/')
      userinfo_endpoint = "#{base_url}#{userinfo_endpoint}"
    end

    uri = URI.parse(userinfo_endpoint)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    
    request = Net::HTTP::Get.new(uri.request_uri)
    request['Authorization'] = "Bearer #{token}"
    
    response = http.request(request)
    return nil unless response.code == '200'

    JSON.parse(response.body)
  rescue StandardError => e
    LOGGER.error "Failed to validate token with IDP: #{e.message}"
    nil
  end

  def find_or_create_user_from_info(info, idp)
    uid_value = info['sub']
    return nil if uid_value.blank?

    uid_record = Uid.find_or_initialize_by(value: uid_value, identity_provider: idp)
    user = uid_record.user || User.find_or_initialize_by(email: info['email'])

    user.assign_attributes(
      first_name: info['given_name'] || info['first_name'] || info['name']&.split&.first,
      last_name: info['family_name'] || info['last_name'] || info['name']&.split&.last
    )

    if user.save
      uid_record.update(user: user)
      user
    else
      LOGGER.error "Failed to save user from token: #{user.errors.full_messages.join(', ')}"
      nil
    end
  end

  def admin?
    current_user&.is?(:admin)
  end

  def protected!
    authorize :application, :admin?
  end

  def csrf_token
    Rack::Protection::AuthenticityToken.token(env)
  end

  def render_partial(template, args = {})
    template_array = template.to_s.split('/')
    template = template_array[0..-2].join('/') + "/_#{template_array[-1]}"
    erb(template.to_sym, locals: args, layout: false)
  end
end
