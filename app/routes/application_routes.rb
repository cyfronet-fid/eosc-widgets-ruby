# frozen_string_literal: true

require_relative './identity_provider'
require_relative './service'
require_relative './session'

get '/' do
  erb :index
end
