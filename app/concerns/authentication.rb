# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  # included do
  #   before_action :restore_authentication
  #   before_action :require_authentication
  #   helper_method :signed_in?
  # end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def signed_in?
    current_user.present?
  end

  def require_authentication
    signed_in? || request_authentication
  end

  def restore_authentication
    if (user = User.find_by(id: session[:user_id]))
      authenticated_as(user)
    end
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect '/'
  end

  def post_authenticating_url
    session.delete(:return_to_after_authenticating) || '/'
  end

  def authenticated_as(user)
    session[:user_id] = user.id
  end

  def reset_authentication
    session.delete(:user_id)
    session.delete(:identity_provider_slug)
    session.delete(:auth)
  end
end
