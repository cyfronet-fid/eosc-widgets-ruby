# frozen_string_literal: true

# Endpoints
get '/endpoints' do
  authorize Endpoint, :index?
  @endpoints = Endpoint.all
  erb :'endpoints/index'
end

get '/endpoints/new' do
  authorize Endpoint, :new?
  @identity_providers = IdentityProvider.all
  @endpoint = Endpoint.new
  erb :'endpoints/new'
end

post '/endpoints' do
  authorize Endpoint, :create?
  @endpoint = Endpoint.new(params[:endpoint])
  if @endpoint.save
    redirect '/endpoints'
  else
    @identity_providers = IdentityProvider.all
    erb :'endpoints/new'
  end
end

get '/endpoints/:id/edit' do
  @endpoint = Endpoint.friendly.find(params[:id])
  authorize @endpoint, :edit?
  @identity_providers = IdentityProvider.all
  erb :'endpoints/edit'
end

put '/endpoints/:id' do
  @endpoint = Endpoint.friendly.find(params[:id])
  authorize @endpoint, :update?
  if @endpoint.update(params[:endpoint])
    redirect '/endpoints'
  else
    @identity_providers = IdentityProvider.all
    erb :'endpoints/edit'
  end
end
