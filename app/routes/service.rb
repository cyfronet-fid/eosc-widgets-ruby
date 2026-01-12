# frozen_string_literal: true

# Services
get '/services' do
  authorize Service, :index?
  @services = Service.all
  erb :'services/index'
end

get '/services/new' do
  authorize Service, :new?
  @identity_providers = IdentityProvider.all
  @service = Service.new
  erb :'services/new'
end

post '/services' do
  authorize Service, :create?
  @service = Service.new(params[:service])
  if @service.save
    redirect '/services'
  else
    @identity_providers = IdentityProvider.all
    erb :'services/new'
  end
end

get '/services/:id/edit' do
  @service = Service.friendly.find(params[:id])
  authorize @service, :edit?
  @identity_providers = IdentityProvider.all
  erb :'services/edit'
end

put '/services/:id' do
  @service = Service.friendly.find(params[:id])
  authorize @service, :update?
  if @service.update(params[:service])
    redirect '/services'
  else
    @identity_providers = IdentityProvider.all
    erb :'services/edit'
  end
end
