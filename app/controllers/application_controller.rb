# frozen_string_literal: true

# Base controlller for application
class ApplicationController < ActionController::Base
  include HttpAuth

  force_ssl if: :ssl_configured?

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.js   { render 'errors/unauthorized', status: 403 }
      format.html { redirect_to '/', alert: exception.message }
      format.json { render json: { errors: { permission: [exception.message] } }, status: 403 }
    end
  end

  # setting locale from URL parameter
  around_action :switch_locale
  def switch_locale(&action)
    locale = params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  protected

  def current_superadmin
    return nil if current_user.nil?
    return nil unless current_user.superadmin?

    current_user
  end

  private

  def ssl_configured?
    Rails.env.production?
  end

  def after_sign_in_path_for(resource)
    if resource.superadmin? || resource.admin?
      rails_admin_url
    else
      root_url
    end
  end
end
