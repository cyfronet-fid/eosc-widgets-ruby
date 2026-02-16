# frozen_string_literal: true

# API Documentation routes
get '/openapi.yaml' do
  content_type 'text/yaml'
  File.read(File.join(settings.root, 'lib', 'widgets', 'documentation', 'openapi.yaml'))
end

get '/docs/swagger' do
  erb :"../../lib/widgets/documentation/views/swagger", layout: false
end
