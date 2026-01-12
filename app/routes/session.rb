# frozen_string_literal: true

get '/auth/:provider' do
  strategy = env['omniauth.strategy']
  if strategy
    OmniAuth.config.logger.info "Initiating auth for #{params[:provider]}. Session ID: #{env['rack.session'].id if env['rack.session'].respond_to?(:id)}"
    response = if OmniAuth.config.test_mode
                 strategy.mock_request_call
               else
                 strategy.request_call
               end

    # Log the Set-Cookie header if present
    status, headers, _body = response
    OmniAuth.config.logger.info "Auth initiation response status: #{status}, Set-Cookie: #{headers['Set-Cookie'] || 'NONE'}"
    OmniAuth.config.logger.info "Session state after strategy call: #{env['rack.session']['omniauth.state']}"

    halt response
  else
    halt 404
  end
end

# Session routes
get '/auth/:provider/callback' do
  auth = request.env['omniauth.auth']
  if auth&.uid
    # Find IdentityProvider by slug (which is used as provider name in OmniAuth)
    idp = IdentityProvider.friendly.find(params[:provider])

    # Find or initialize user based on UID and IDP
    uid_record = Uid.find_or_initialize_by(value: auth.uid, identity_provider: idp)
    user = uid_record.user || User.find_or_initialize_by(email: auth.info['email'])

    # Map attributes from OmniAuth info
    user.assign_attributes(
      first_name: auth.info['first_name'] || auth.info['name']&.split&.first,
      last_name: auth.info['last_name'] || auth.info['name']&.split&.last
    )

    if user.save
      uid_record.update(user: user)
      authenticated_as(user)
      session[:identity_provider_slug] = params[:provider]
      redirect post_authenticating_url
    else
      redirect '/'
    end
  else
    redirect '/'
  end
end

get '/auth/failure' do
  redirect '/'
end

get '/logout' do
  provider = session[:identity_provider_slug]
  reset_authentication
  if provider
    # Try to logout from Identity Provider as well
    redirect "/auth/#{provider}/logout"
  else
    redirect '/'
  end
end

delete '/logout' do
  provider = session[:identity_provider_slug]
  reset_authentication
  if provider
    redirect "/auth/#{provider}/logout"
  else
    redirect '/'
  end
end

