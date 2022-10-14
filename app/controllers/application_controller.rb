class ApplicationController < ActionController::Base
  include SSLWithConfiguredPort

  before_action :allow_super_admin!
  before_action :authenticate_user_from_token!
  before_action :authenticate_user!, :update_current_session
  before_action :set_locale
  before_action :set_time_zone
  before_action :set_switchable_users

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :task_filter_collection
  helper_method :association_task_filter_collection
  # helper_method :is_admin?
  # helper_method :is_agent?
  before_action :set_user_role_instance


  AVAILABLE_LOCALES = ['en', 'fi', 'sv']

  def set_switchable_users
    if current_user.try(:has_role?, :admin)
      @q                = ::User.accessible_by(current_ability).where("id != ?", current_user.id).ransack
      @q.sorts          = 'full_name_format asc'
      @switchable_users = @q.result(distinct: false).decorate
    end

    if session[:original_admin_id] > 0
      @relogin_as_admin = true
    end if session[:original_admin_id]
  end

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.js do
        head(status: :unauthorized)
      end
      format.html do
        if current_user.has_role?(:admin)
          redirect_to main_dashboard_url, :alert => exception.message
        else
          redirect_to root_url, :alert => exception.message
        end
      end
    end
  end

  def default_url_options(options = {})
    { locale: I18n.locale }
  end

  def current_user
    UserDecorator.decorate(super) if super
  end

  def all_service_channel
    ::ServiceChannel.all
  end

  def after_sign_in_path_for(resource)
    case resource
    when ::User
      if resource.has_role?('admin')
        main_dashboard_url
      else
        root_url
      end
    when ::SuperAdmin
      super_ui_url
    else
      super(resource)
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    case resource_or_scope
    when :user, ::User
      new_user_session_url
    when :super_admin, ::SuperAdmin
      new_super_admin_session_url
    else
      new_user_session_url
    end
  end

  def check_admin_access
    raise CanCan::AccessDenied unless current_user.has_role?(:admin)
    @admin_page = true
  end

  def check_agent_access
    logger.info "==================LOGGING========================APPLICATION CONTROLLER CHECK AGENT"
    raise CanCan::AccessDenied unless current_user.has_role?(:agent)
    logger.info "==================LOGGING========================APPLICATION CONTROLLER CHECK AGENT"
  end

  private

  def allow_super_admin!
    if current_super_admin.present?
      user_email = params[:email].presence
      user       = user_email && User.where(email: user_email).first
      if user
        sign_in(:user, user)
        @current_user = user
      end
    end
  end

  def authenticate_user_from_token!
    user_email = params[:email].presence
    user       = user_email && User.where(email: user_email).first
    if user && Devise.secure_compare(user.authentication_token, params[:token])
      sign_in user
    end
  end

  def set_locale
    if params[:locale].present? && params[:locale] != cookies[:_locale] && available_locale?(params[:locale])
      locale = params[:locale]
      save_locale(params[:locale])
    elsif cookies[:_locale] && available_locale?(params[:locale])
      locale = cookies[:_locale]
    elsif header_locale = extract_locale_from_accept_language_header
      save_locale(header_locale)
      locale = header_locale
    else
      locale = I18n.default_locale
    end
    I18n.locale = locale
  end

  def set_time_zone
    Time.zone = current_user.company.try(:time_zone) if user_signed_in?
  end

  def current_session
    return unless current_user
    @current_session ||= current_user.sessions.where(session_id: cookies.signed[:_session_id]).first
  end

  def update_current_session
    return unless current_session
    current_session.accessed!(request)
  end

  def get_ransack_query(cookie_key)
#    cookies.delete(cookie_key) if params[:clear]
#    cookies[cookie_key] = params[:q].to_json if params[:q]
#    @query              = params[:q].presence || JSON.load(cookies[cookie_key] || '{}')
    @query = params[:q].presence || {}
  end

  private

  def extract_locale_from_accept_language_header
    return nil unless request.env['HTTP_ACCEPT_LANGUAGE']
    if locale = current_user.try(:locale) || request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
      return locale if available_locale?(locale)
    end
  end

  def save_locale(locale)
    cookies.permanent[:_locale] = locale
  end

  def available_locale?(locale)
    AVAILABLE_LOCALES.include?(locale.to_s)
  end

  def task_filter_collection
    arr = []
    %w(new open waiting ready).each do |state|
      arr << [t("activerecord.models.task.states.#{state}"), state]
    end
    arr
  end

  def association_task_filter_collection(selected = nil)
    arr = []
    options = %w(open_to_all created_by_me assigned_to_me)
    options = options + %w(assigned_to_other i_am_following) unless selected
    options.each do |association_type|
      arr << [t("activerecord.models.task.association_types.#{association_type}"), association_type]
    end
    arr
  end

  def set_user_role_instance
    @is_admin ||= current_user.try(:has_role?, :admin)
    @is_agent ||= current_user.try(:has_role?, :agent)
  end

end
