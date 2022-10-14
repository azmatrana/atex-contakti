class Api::V1::BaseController < ActionController::Base
  before_filter :cors_preflight_check
  after_filter :cors_set_access_control_headers

  before_filter :authenticate_user!, :except => [:get_chat_settings, :get_translations, :get_shipment_methods, :create_task_from_chat, :send_quit, :set_client_info,:set_client_connected,:has_client_left, :bot_initiate_human_chat, :initiate_chat, :send_msg, :create_callback, :send_email_chat_history, :uploadfile, :abort_chat,:send_indicator]
  before_filter :authenticate_user_from_token!, :except => [:get_chat_settings, :get_translations, :get_shipment_methods, :create_task_from_chat, :send_quit, :set_client_info, :set_client_connected, :has_client_left, :bot_initiate_human_chat, :initiate_chat, :send_msg, :create_callback, :send_email_chat_history, :uploadfile, :abort_chat, :send_indicator], :unless => proc {|_| current_user.present?}

  before_action :set_locale,
                :set_time_zone

  respond_to :json

  rescue_from CanCan::AccessDenied do |exception|
    head(status: :unauthorized)
  end

  def resource_not_found
    render json: 'Not found', status: 404
  end

  # If this is a preflight OPTIONS request, then short-circuit the
  # request, return only the necessary headers and return an empty
  # text/plain.

  def cors_preflight_check
    if request.method == "OPTIONS"
      cors_set_access_control_headers
      render :text => 'ok', :content_type => 'text/plain', :status => 200
    end
  end

  def get_ransack_query(cookie_key)
#    cookies.delete(cookie_key) if params[:clear]
#    cookies[cookie_key] = params[:q].to_json if params[:q]
#    @query              = params[:q].presence || JSON.load(cookies[cookie_key] || '{}')
    @query = params[:q].presence || {}
  end

  protected
  # For all responses in this controller, return the CORS access control headers.
  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS, PUT, DELETE, PATCH'
    headers['Access-Control-Allow-Headers'] = 'X-Auth-Email, X-Auth-Token, X-Requested-With, Content-Type'
    headers['Access-Control-Max-Age'] = "1728000"
  end


  def authenticate_user_from_token!
    user_email = params[:email].presence || request.headers['X-Auth-Email'].presence
    user       = user_email && User.where(email: user_email).first

    if user && Devise.secure_compare(user.authentication_token, params[:token].presence || request.headers['X-Auth-Token'].presence)
      sign_in user, store: false
    else
      raise CanCan::AccessDenied
    end
  end

  def check_agent_access
    raise CanCan::AccessDenied unless current_user.present? && current_user.has_role?(:agent)
  end

  def set_locale
    begin
      locale = cookies[:i18next] || params[:locale] || session[:locale] || get_request_locale || I18n.default_locale
      if locale != session[:locale]
        session[:locale] = locale
      end

      I18n.locale = locale
    rescue
      I18n.locale = I18n.default_locale
    end
  end

  def set_time_zone
    ::Time.zone = current_user.company.time_zone if user_signed_in?
  end

  private
  # Detect the locale based on browser headers
  def get_request_locale
    rloc = request.env['HTTP_ACCEPT_LANGUAGE']
    if rloc
      # We assume the languages are already in the preferred order as most
      # browsers should send this header in prioritized format. Therefore, we
      # are only interested in the locale part
      locales = rloc.gsub(/([a-z]+)(-[A-Z]+)?;q=[0-9\.]+/, '\1').split(",").uniq
      return locales.detect { |loc| I18n.locale_available? loc }
    end
    nil
  end
end
