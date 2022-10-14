class AgentsController < ApplicationController
  before_action :check_admin_access
  before_action :set_common_variables, except: [:filter_message]
  before_action :create_or_update_agent, only: [:create, :update]

  def index

    render :index
  end

  def new
    @show_form = true
    render :index
  end

  def show
    load_sms_template
    load_skills
    render :index
  end

  def search

  end

  def create
    if @user.save
      redirect_to agent_path(@user), notice: I18n.t('users.agents.added_agent')
    else
      error_messages = "Errors: #{@user.errors.full_messages}"
      logger.info error_messages
      flash[:notice] = error_messages
      @show_form = true
      render :index
    end
  end

  def update
    clear_sip_settings
    if @user.save
      redirect_to agent_path(@user), notice: I18n.t('users.agents.updated_agent')
    else
      error_messages = "Errors: #{@user.errors.full_messages}"
      logger.info error_messages
      flash[:notice] = error_messages
      load_skills
      render :index
    end
  end

  def destroy
    notice = if @user.destroy
               I18n.t('users.agents.deleted_agent')
             else
               I18n.t('users.agents.not_deleted_agent')
             end
    redirect_to agents_url, notice: notice
  end

  def create_or_update_agent
    @user.attributes = user_params

    unless @user.persisted?
      @user.company_id = current_user.company_id
      @user.password = @user.get_random_password
      @user.created_by_manager!
    end
  end

  def filter_message
    @user = ::User.accessible_by(current_ability).where(id: params[:id]).first
    @user_messages =
      case params[:by]
      when I18n.t('users.agents.today').try(:downcase)
        tasks = @user.tasks.where('date(assigned_at) = ?', ::Time.current.to_date).select(:id)
        @user.messages.where(task_id: tasks).decorate
      when I18n.t('users.agents.open').try(:downcase), I18n.t('users.agents.waiting').try(:downcase), I18n.t('users.agents.ready').try(:downcase)
        tasks = @user.tasks.where(state: params[:by]).select(:id)
        @user.messages.where(task_id: tasks).decorate
      else
        @user.messages.decorate
      end
  end

  def render_activity_report
    @report = ::Report.new(kind: 'comparison', company_id: current_user.company_id)
    @report.user_ids = [@user.id]
    @report.attributes = params.permit(:starts_at, :ends_at)
    @data = @report.get_data
    respond_to do |format|
      format.js
    end
  end

  def create_sms_template
    load_sms_template
    temp = @sms_template
    @sms_template.attributes = sms_template_params
    @sms_template.author_id  = current_user.id
    @sms_template.company_id = current_user.company_id
    @sms_template.visibility = :service_channel if @sms_template.visibility.blank? && @sms_template.for_agent?
    @sms_template.save
    @service_channel         = @sms_template.service_channel || ::ServiceChannel.find(params[:manager_template][:service_channel_id])
    set_common_variables
    @sms_template = temp
    if @sms_template.errors.empty?
      @status_message = { ok: true, text: I18n.t('service_channels.sms_template_saved') }
    else
      logger.info "Errors: #{@sms_template.errors.full_messages}"
    end
    @service_channels = ::ServiceChannel.shared.accessible_by(current_ability)
    render :update_form
  end

  def destroy_sms_template
    id = params[:id]
    if id.present?
      @sms_template    = ::SmsTemplate.find id
      @service_channel = @sms_template.service_channel
      templateKind     = @sms_template.kind
      if @sms_template.destroy
        @sms_template = ::SmsTemplate.new(kind: templateKind)
        @status_message = { ok: true, text: I18n.t('service_channels.sms_template_deleted') }
      end
    else
      @sms_template = ::SmsTemplate.new(kind: params[:kind])
      @service_channel = ::ServiceChannel.find params[:service_channel_id]
      @status_message = { ok: false, text: I18n.t('service_channels.cannot_delete_template') }
    end
    set_common_variables
    render :update_form
  end

  def create_skills
    if params[:tag].present?
      tag = params[:tag]
      sanitized = tag.downcase.gsub(/[^a-zåäö0-9@\.\-\_\+\?\/\:]/, "").gsub(/\&.+?;/, "").gsub(/%\d+/, "")
      @user.skill_list.add(sanitized) unless sanitized.blank?
      # Convert task generic tags to skill tags when a matching skill has been added to company
      @user.tasks.tagged_with(sanitized, on: :generic_tags).each do |task|
        task.generic_tag_list.remove(sanitized)
        task.skill_list.add(sanitized)
        task.save
      end
      @user.save!
      @user.touch # invalidate tag cache
    end
    @all_skills = @user.company.skills
    @skills = @user.skills

    @all_skills = @all_skills - @skills
    @skill_counts = @user.tag_usage_count
  end

  def destroy_skills
    if params[:tag].present?
      @user.skill_list.remove(params[:tag])

      # Convert task skill tags to generic tags because the company skill has been removed
      @user.tasks.tagged_with(params[:tag], on: :skills).each do |task|
        task.skill_list.remove(params[:tag])
        task.generic_tag_list.add(params[:tag])
        task.save
      end
      @user.save
      @user.touch # invalidate tag cache
    end
    @all_skills = @user.company.skills
    @skills = @user.skills

    @all_skills = @all_skills - @skills
    @skill_counts = @user.tag_usage_count
  end

  private

  def set_common_variables
    @q                = ::User.with_role(:agent).accessible_by(current_ability).ransack(get_ransack_query('query_agents'))
    @q.sorts          = 'full_name_format asc' if @q.sorts.empty?
    @agents           = @q.result(distinct: false).decorate
    @service_channels = ::ServiceChannel.shared.accessible_by(current_ability)
    @locations        = ::Location.accessible_by(current_ability)
    @user             = params[:id] ? ::User.find(params[:id]) : ::User.new
    authorize!(:read, @user) if @user.persisted?
    @user_messages    = @user.messages.order('created_at desc').decorate
    @service_channel = @service_channels.first
    @sms_template = ::SmsTemplate.new
    @sms_templates = @service_channel.try(:agent_sms_templates)
    gon.sms_templates = @sms_templates
    @manager_template = ::SmsTemplate.new
    if @sms_template.for_agent?
      @sms_templates        = @service_channel.try(:agent_sms_templates)
      gon.sms_templates     = @sms_templates
    else
      @manager_template     = @sms_template
      @manager_templates    = ::SmsTemplate.for_manager.accessible_by(current_ability)
      gon.manager_templates = @manager_templates
    end
  end

  def user_params
    @user_params ||= params.require(:user).permit(
      :first_name,
      :last_name,
      :alias_name,
      :title,
      :mobile,
      :email,
      :default_location_id,
      location_ids: [],
      service_channel_ids: [],
      media_channel_types: [],
      smtp_settings: [
        :id, :description, :server_name, :port, :auth_method, :user_name, :password, :use_ssl
      ],
      imap_settings: [
        :id, :description, :from_email, :from_full_name, :server_name,
        :port, :user_name, :password, :use_ssl
      ],
      sip_settings_attributes: [
        :id, :title, :domain, :user_name, :password, :ws_server_url
      ]
    )

    if @user_params[:sip_settings_attributes]
      @user_params.delete(:sip_settings_attributes) unless @user_params[:sip_settings_attributes].detect { |key, value| key != 'id' && !value.blank? }
    end

    @user_params
  end

  def load_skills
    @skills = @user.skills
    @all_skills = @user.company.skills - @skills
    @skill_counts = @user.tag_usage_count
  end

  def sms_template_params
    @sms_template_params ||= params[:sms_template].permit(:kind, :title, :text, :service_channel_id, :visibility, :location_id)
  end

  def load_sms_template

    begin
        id            = params[:sms_template][:id]
        @sms_template = id.present? && params[:sms_template][:save_as_new] != 'true' ? ::SmsTemplate.find(id) : ::SmsTemplate.new
        if params[:sms_template][:save_as_new] == 'false' && id.blank? && params[:sms_template][:title].present?
          @sms_template = ::SmsTemplate.where(title: params[:sms_template][:title])
                                       .where(
                                          params[:sms_template][:kind] == 'agent' ?
                                            { service_channel_id: params[:sms_template][:service_channel_id] }
                                            : { company_id: current_user.company_id }
                                       ).first
        end
    rescue
        service_channels = ::ServiceChannel.shared.accessible_by(current_ability)
        service_channel = @service_channels.first
        print service_channel.agent_sms_templates.length,"service_channel.agent_sms_templatesservice_channel.agent_sms_templates"
        @sms_template = service_channel.agent_sms_templates.first
    end
  end

  def clear_sip_settings
    if @user.sip_settings && params[:user] && params[:user][:sip_settings_attributes] && !params[:user][:sip_settings_attributes].detect { |key, value| key != 'id' && !value.blank? }
      @user.sip_settings.destroy
      @user.reload
    end
  end

end
