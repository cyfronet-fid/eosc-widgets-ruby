# frozen_string_literal: true

require 'json'

# Favourites
get '/favourites' do
  require_authentication
  @favourites = current_user.favourites
  erb :"../../lib/widgets/favourites/views/index"
end

# Favourites API
post '/api/favourites' do
  is_json = request.content_type == 'application/json' || request.accept.any? { |a| a.to_s == 'application/json' }
  content_type :json if is_json
  
  unless signed_in?
    error_msg = { error: 'Unauthorized' }.to_json
    return is_json ? [401, error_msg] : halt(401, 'Unauthorized')
  end

  fav_params = params[:favourite]
  if fav_params.nil? && request.content_type == 'application/json'
    begin
      fav_params = JSON.parse(request.body.read, symbolize_names: true)[:favourite]
    rescue JSON::ParserError
      # Ignore
    end
  end
  
  if fav_params.nil?
    error_msg = { error: 'Missing favourite parameters' }.to_json
    return is_json ? [400, error_msg] : [400, 'Missing parameters']
  end

  begin
    favourite = Favourite.find_or_initialize_by(
      pid: fav_params[:pid],
      type: fav_params[:type]
    )
    
    favourite.assign_attributes(
      title: fav_params[:title],
      authors: fav_params[:authors],
      links: fav_params[:links],
      best_access_right: fav_params[:best_access_right]
    )
    
    favourite.save!

    unless current_user.favourites.exists?(favourite.id)
      current_user.favourites << favourite
    end

    if is_json
      status 201
      favourite.to_json
    else
      redirect back
    end
  rescue StandardError => e
    LOGGER.error "Failed to add favourite: #{e.message}"
    if is_json
      halt 422, { error: e.message }.to_json
    else
      halt 422, "Error: #{e.message}"
    end
  end
end

delete '/api/favourites' do
  # Debug
  # puts "Accept: #{request.accept.inspect}"
  # puts "Content-Type: #{request.content_type.inspect}"

  is_json = request.content_type == 'application/json' || request.accept.any? { |a| a.to_s == 'application/json' }
  content_type :json if is_json

  unless signed_in?
    error_msg = { error: 'Unauthorized' }.to_json
    return is_json ? [401, error_msg] : halt(401, 'Unauthorized')
  end

  pid = params[:pid]
  resource_type = params[:type]

  if pid.nil? || resource_type.nil?
    # Try to parse from JSON body if not in params
    begin
      body_params = JSON.parse(request.body.read, symbolize_names: true)
      pid ||= body_params[:pid]
      resource_type ||= body_params[:type]
    rescue JSON::ParserError
      # Ignore
    end
  end

  if pid.nil? || resource_type.nil?
    error_msg = { error: 'Missing pid or resource_type' }.to_json
    return is_json ? [400, error_msg] : [400, 'Missing parameters']
  end

  favourite = Favourite.find_by(pid: pid, type: resource_type)
  if favourite
    current_user.favourites.delete(favourite)
    if is_json
      status 204
      ''
    else
      redirect '/favourites'
    end
  else
    error_msg = { error: 'Favourite not found' }.to_json
    is_json ? [404, error_msg] : [404, 'Not found']
  end
end
