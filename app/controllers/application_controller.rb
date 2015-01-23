class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_locale
  def set_locale
    if ! request.format.json?
      logger.debug "* Accept-Language: #{request.env['HTTP_ACCEPT_LANGUAGE']}"
      set_correct_locale
      logger.debug "* Locale set to '#{I18n.locale}'"
    end
  end

  private

  def set_correct_locale
    request.env['HTTP_ACCEPT_LANGUAGE'].scan(/[a-z]{2}/).uniq.each do |locale|
      logger.debug "Testing locale #{locale}"
      begin
        I18n.locale = locale
        return
      rescue
      end
    end
    logger.debug "Valid locale not found, setting default locale"
    I18n.locale = I18n.default_locale
  end
end
