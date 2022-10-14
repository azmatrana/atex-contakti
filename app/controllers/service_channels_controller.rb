class ServiceChannelsController < ApplicationController
  before_action :check_admin_access
  before_action :set_common_variables, except: [:destroy, :test_imap_settings, :test_smtp_settings]
  load_and_authorize_resource
  skip_load_and_authorize_resource only: [:index, :new]

  def index
  end

  def new
    @show_form = true
    render :index
  end

  def show
    set_common_variables
    render :index
  end

  def search
  end

  def destroy
    @service_channel = ::ServiceChannel.find(params[:id])
    authorize! :manage, @service_channel
    notice = I18n.t('service_channels.will_be_removed')
    ::ServiceChannelDestroyWorker.perform_async(@service_channel.id)
    redirect_to service_channels_path, notice: notice
  end

  def delete_service_tasks
    service_channel = ::ServiceChannel.find(params[:id])
    authorize! :manage, @service_channel
    tasks = service_channel.tasks
    tasks.destroy_all

    service_channel.chat_records.destroy_all
    service_channel.chatbot_stats.destroy_all
    service_channel.orders.destroy_all

    redirect_to :back
  end

  def update
    fix_sip_media_channel
    fix_media_channel_active_states
    fix_call_media_channel_checkboxes
    fix_email_media_channel_checkboxes
    @service_channel = params[:id] ? ::ServiceChannel.find(params[:id]) : ::ServiceChannel.new
    if params[:service_channel]
      if params[:service_channel][:sms_media_channel_attributes].present?
        @service_channel.attributes = sms_media_channel_params
        @service_channel.company_id = current_user.company_id
      else
        @service_channel.attributes = service_channel_params
        @service_channel.company_id = current_user.company_id
      end
    end
    if @service_channel.errors.empty? && @service_channel.save
      flash[:notice] = I18n.t('service_channels.service_channel_saved')
      @service_channel.run_all_test_checks
    else
      logger.info "Errors on saving service chanel: #{@service_channel.errors.full_messages}"
    end
    if !params[:id] && @service_channel.persisted?
      redirect_to @service_channel
    else
      set_common_variables
      @show_form = true
      render :action => :index
    end
  end

  def test_imap_settings
    test_result = ::ImapService.test(params)
    message = test_result[:success] ? ::I18n.t('views.service_channels.imap_settings.test_success') :
                (::I18n.t('views.service_channels.imap_settings.test_error') % test_result[:message])
    render json: {ok: test_result[:success], message: message}
  end

  def test_smtp_settings
    test_result = ::SmtpService.test(params)
    message = test_result[:success] ? ::I18n.t('views.service_channels.smtp_settings.test_success') :
                (::I18n.t('views.service_channels.smtp_settings.test_error') % test_result[:message])
    render json: {ok: test_result[:success], message: message}
  end

  def create_skills
    if params[:tag].present?
      tag = params[:tag]
      sanitized = tag.downcase.gsub(/[^a-zåäö0-9\.\-\_\+\?\/\:]/, "").gsub(/\&.+?;/, "").gsub(/%\d+/, "")
      @service_channel.skill_list.add(sanitized) unless sanitized.blank?
      # Convert task generic tags to skill tags when a matching skill has been added to company
      @service_channel.tasks.tagged_with(sanitized, on: :generic_tags).each do |task|
        task.generic_tag_list.remove(sanitized)
        task.skill_list.add(sanitized)
        task.save
      end
      @service_channel.save!
      @service_channel.touch # invalidate tag cache
    end
    @skills = @service_channel.skills
    @skill_counts = @service_channel.tag_usage_count
  end

  def destroy_skills
    if params[:tag].present?
      @service_channel.skill_list.remove(params[:tag])

      # Convert task skill tags to generic tags because the company skill has been removed
      @service_channel.tasks.tagged_with(params[:tag], on: :skills).each do |task|
        task.skill_list.remove(params[:tag])
        task.generic_tag_list.add(params[:tag])
        task.save
      end
      @service_channel.save
      @service_channel.touch # invalidate tag cache
    end
    @skills = @service_channel.skills
    @skill_counts = @service_channel.tag_usage_count
  end

  private

  def fix_sip_media_channel
    return unless params[:service_channel][:sip_media_channel_attributes]
    if params[:service_channel][:sip_media_channel_attributes][:sip_settings_attributes][:title].blank?
      params[:service_channel][:sip_media_channel_attributes][:sip_settings_attributes] = nil
    end
  end

  def fix_media_channel_active_states
    return unless params[:service_channel]
    %w(email web_form call chat internal sip).each do |key|
      attributes_key = "#{key}_media_channel_attributes".to_sym
      next unless params[:service_channel][attributes_key]
      params[:service_channel][attributes_key][:active] = params[:service_channel][attributes_key][:active] == '1' ? true : false
    end
  end

  def fix_call_media_channel_checkboxes
    return unless params[:service_channel]
    return unless params[:service_channel][:call_media_channel_attributes]
    %i[name_check send_autoreply mark_done_on_call_action].each do |boolean_field|
      unless params[:service_channel][:call_media_channel_attributes][boolean_field]
        params[:service_channel][:call_media_channel_attributes][boolean_field] = 0
      end
    end
  end

  def fix_email_media_channel_checkboxes
    %w(email web_form).each do |key|
      attributes_key = "#{key}_media_channel_attributes".to_sym
      next unless params[:service_channel][attributes_key]
      %w(smtp imap).each do |from|
        channel_key = "#{from}_settings_attributes"
        next unless params[:service_channel][attributes_key][channel_key]
        unless params[:service_channel][attributes_key][channel_key][:use_ssl]
          params[:service_channel][attributes_key][channel_key][:use_ssl] = 0
        end
      end

    end
  end

  def set_common_variables
    @service_channel ||= params[:id] ? ::ServiceChannel.find(params[:id]) : ::ServiceChannel.new
    authorize!(:read, @service_channel) if @service_channel.persisted?

    unless @service_channel.email_media_channel(broken: true)
      @service_channel.build_email_media_channel
      @service_channel.email_media_channel.build_imap_settings
      @service_channel.email_media_channel.build_smtp_settings
    end
    unless @service_channel.web_form_media_channel(broken: true)
      @service_channel.build_web_form_media_channel
      @service_channel.web_form_media_channel.build_imap_settings
      @service_channel.web_form_media_channel.build_smtp_settings
    end
    unless @service_channel.chat_media_channel
      @service_channel.build_chat_media_channel
      @service_channel.chat_media_channel.active = 0
    end
    unless @service_channel.internal_media_channel
      @service_channel.build_internal_media_channel
    end

    @service_channel.internal_media_channel.active = 1
    @service_channel.internal_media_channel.save if @service_channel.persisted?

    @service_channel.build_call_media_channel(broken: true) unless @service_channel.call_media_channel
    @service_channel.build_sip_media_channel(broken: true) unless @service_channel.sip_media_channel

    @q = ::ServiceChannel.shared.accessible_by(current_ability)
                         .ransack(get_ransack_query('query_service_channels'))
    @q.sorts = 'name asc' if @q.sorts.empty?
    @service_channels = @q.result(distinct: true)
    @agents = ::User.with_role(:agent).accessible_by(current_ability).order('first_name asc, last_name asc').decorate

    # TODO: add company scope for ImapSettings as well
    @imap_settings = ::ImapSettings.accessible_by(current_ability)
    @locations = ::Location.accessible_by(current_ability)
    @sms_template = ::SmsTemplate.new
    @sms_templates = @service_channel.agent_sms_templates
    gon.sms_templates = @sms_templates

    @manager_template = ::SmsTemplate.new
    @service_channel.weekly_schedule ||= WeeklySchedule.new
    @service_channel.email_media_channel.weekly_schedule || @service_channel.email_media_channel.build_weekly_schedule
    @service_channel.web_form_media_channel.weekly_schedule || @service_channel.web_form_media_channel.build_weekly_schedule
    @service_channel.call_media_channel.weekly_schedule || @service_channel.call_media_channel.build_weekly_schedule
    @manager_templates = ::SmsTemplate.for_manager.accessible_by(current_ability)
    gon.manager_templates = @manager_templates

    @skills = @service_channel.skills
    @all_skills = @service_channel.company.skills rescue []
    @skill_counts = @service_channel.tag_usage_count

  end

  def email_settings_params
    @email_settings_params ||= [
      :id,
      :active,
      :yellow_alert_days,
      :yellow_alert_hours,
      :yellow_alert_minutes,
      :red_alert_days,
      :red_alert_hours,
      :red_alert_minutes,
      :autoreply_text,
      :send_autoreply,
      :autoreply_email_subject,
      weekly_schedule_attributes: weekly_schedule_attributes,
      imap_settings_attributes: [
        :id,
        :server_name,
        :user_name,
        :password,
        :description,
        :port, :use_ssl,
        :from_email,
        :from_full_name
      ],
      smtp_settings_attributes: [
        :id,
        :server_name,
        :user_name,
        :password,
        :description,
        :port,
        :use_ssl,
        :auth_method,
        :use_contakti_smtp
      ]
    ]
  end

  def weekly_schedule_attributes
    [
      :id,
      :open_full_time,
      schedule_entries_attributes: [
        :id, :start_time, :end_time, :_destroy, :weekday
      ]
    ]
  end

  def sip_settings_params
    [
      :id,
      :active,
      sip_settings_attributes: [
        :id, :title, :domain, :user_name, :password, :ws_server_url,
        sip_widget_attributes: [
          :id,
          :button_1,
          :button_1_extension,
          :button_2,
          :button_2_extension,
          :button_3,
          :button_3_extension,
          :button_4,
          :button_4_extension,
          :button_5,
          :button_5_extension,
          :button_6,
          :button_6_extension,
          :widget_button_color,
          :dial_color,
          :dial_bg_color,
        ]
      ]
    ]
  end

  def sms_media_channel_params
    params.require(:service_channel).permit(
      sms_media_channel_attributes: [
        :id,
        :yellow_alert_days,
        :yellow_alert_hours,
        :yellow_alert_minutes,
        :red_alert_days,
        :red_alert_hours,
        :red_alert_minutes,
        :sms_sender
      ]
    )
  end

  def service_channel_params
    params[:service_channel][:user_ids] ||= [] if params[:service_channel].present?
    @service_channel_params ||= params.require(:service_channel).permit(
      :name,
      :yellow_alert_hours,
      :yellow_alert_days,
      :yellow_alert_minutes,
      :red_alert_hours,
      :red_alert_days,
      :red_alert_minutes,
      :signature,
      location_ids: [],
      user_ids: [],
      email_media_channel_attributes: email_settings_params,
      internal_media_channel_attributes: [
        :id,
        :active,
        :yellow_alert_days,
        :yellow_alert_hours,
        :yellow_alert_minutes,
        :red_alert_days,
        :red_alert_hours,
        :red_alert_minutes
      ],
      web_form_media_channel_attributes: email_settings_params,
      call_media_channel_attributes: [
        :id,
        :group_id,
        :autoreply_text,
        :active,
        :name_check,
        :send_autoreply,
        :yellow_alert_days,
        :yellow_alert_hours,
        :yellow_alert_minutes,
        :red_alert_days,
        :red_alert_hours,
        :red_alert_minutes,
        :sms_sender,
        :mark_done_on_call_action,
        weekly_schedule_attributes: weekly_schedule_attributes
      ],
      chat_media_channel_attributes: [
        :id,
        :autoreply_text,
        :active,
        :yellow_alert_days,
        :yellow_alert_hours,
        :yellow_alert_minutes,
        :red_alert_days,
        :red_alert_hours,
        :red_alert_minutes,
        chat_settings_attributes: [
          :id,
          :format,
          :enable_chatbot,
          :file,
          :whitelisted_referers,
          :color,
          :text_color,
          :welcome_message,
          :initial_msg,
          :bot_alias,
          :enable_cart,
          :chat_title,
          :enable_initial_buttons,
          :checkout_paytrail,
          :checkout_ticket,
          :paytrail_payment_success_url,
          :paytrail_payment_failure_url,
          chat_inquiry_fields_attributes: [:title, :id, :_destroy],
          chat_initial_buttons_attributes: [:id, :title, :_destroy]
        ]
      ],
      sms_media_channel_attributes: [
        :id,
        :yellow_alert_days,
        :yellow_alert_hours,
        :yellow_alert_minutes,
        :red_alert_days,
        :red_alert_hours,
        :red_alert_minutes,
        :sms_sender
      ],
      weekly_schedule_attributes: weekly_schedule_attributes,
      sip_media_channel_attributes: sip_settings_params
    )
  end



end
