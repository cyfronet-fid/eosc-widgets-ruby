# frozen_string_literal: true

require_relative '../test_helper'

class DocumentationRoutesTest < Minitest::Test
  def test_openapi_yaml
    get '/openapi.yaml'
    assert last_response.ok?
    assert_equal 'text/yaml;charset=utf-8', last_response.content_type
    assert_includes last_response.body, 'openapi: 3.0.3'
  end

  def test_swagger_ui
    get '/docs/swagger'
    assert last_response.ok?
    assert_includes last_response.body, 'id="swagger-ui"'
    assert_includes last_response.body, 'url: "/openapi.yaml"'
  end
end
