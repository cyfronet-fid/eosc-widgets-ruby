# frozen_string_literal: true

helpers do
  include Pundit::Authorization

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
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
