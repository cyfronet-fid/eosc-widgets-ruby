# frozen_string_literal: true

# Profile
get '/profile' do
  require_authentication
  @auth_data = session[:auth] || {}
  erb :"../../lib/widgets/profile/views/show"
end
