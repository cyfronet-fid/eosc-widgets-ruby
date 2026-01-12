# frozen_string_literal: true

# Identity Providers
get '/identity_providers' do
  authorize IdentityProvider, :index?
  @identity_providers = IdentityProvider.all
  erb :'identity_providers/index'
end

get '/identity_providers/new' do
  authorize IdentityProvider, :new?
  @identity_provider = IdentityProvider.new
  erb :'identity_providers/new'
end

post '/identity_providers' do
  authorize IdentityProvider, :create?
  idp_params = params[:identity_provider]
  if idp_params && idp_params[:config].is_a?(String)
    begin
      idp_params[:config] = JSON.parse(idp_params[:config]) unless idp_params[:config].empty?
    rescue JSON::ParserError => e
      # If JSON is invalid, we keep it as a string,
      # ActiveRecord will throw an error on save attempt or we'll handle it otherwise
      LOGGER.error "JSON parsing error for IdentityProvider config: #{e.message}" if defined?(LOGGER)
    end
  end
  @identity_provider = IdentityProvider.new(idp_params)
  if @identity_provider.save
    redirect '/identity_providers'
  else
    erb :'identity_providers/new'
  end
end

get '/identity_providers/:id/edit' do
  @identity_provider = IdentityProvider.friendly.find(params[:id])
  authorize @identity_provider, :edit?
  erb :'identity_providers/edit'
end

put '/identity_providers/:id' do
  @identity_provider = IdentityProvider.friendly.find(params[:id])
  authorize @identity_provider, :update?
  idp_params = params[:identity_provider]
  if idp_params && idp_params[:config].is_a?(String)
    begin
      idp_params[:config] = JSON.parse(idp_params[:config]) unless idp_params[:config].empty?
    rescue JSON::ParserError => e
      # Ignore the error, ActiveRecord will throw a validation error if the type doesn't match
      LOGGER.error "JSON parsing error for IdentityProvider update: #{e.message}" if defined?(LOGGER)
    end
  end
  if @identity_provider.update(idp_params)
    redirect '/identity_providers'
  else
    erb :'identity_providers/edit'
  end
end
