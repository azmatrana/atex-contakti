class TasksController < ApplicationController
  include TasksHelper

  before_action :set_common_variables,
    except: [:danthes_subscribe, :set_user_online, :subscribe_agents, :mark_message_as_read, :get_tasks, :current_user_tasks, :get_ready_tasks, :current_user_ready_tasks, :danthes_bulk_subscribe, :change_in_call_status, :subscribe_to_agents_in_call_status, :get_all_agents]
  before_action :check_agent_access
  before_action :load_task_by_id,
    except: [:index, :set_user_online, :mark_message_as_read, :current_user_tasks, :current_user_ready_tasks, :danthes_subscribe, :danthes_bulk_subscribe, :search, :super_search, :create, :get_tasks, :get_ready_tasks, :call_history, :add_call_history, :get_customer_tasks, :get_customer_ready_tasks, :search_archived, :search_unsolved, :get_agents_by_service_channel_id, :subscribe_agents, :search_agents, :send_email, :get_all_service_channels, :get_task_by_id, :create_sms_template, :manage, :send_chat_history, :change_in_call_status, :subscribe_to_agents_in_call_status, :get_all_agents]
  before_action :load_task_for_manage, only: [:manage]

  def index
    set_user_online
    load_sms_template
    current_user.prepare_agent_channels

    #@tasks            = current_user_tasks
    #message_table     = ::Message.arel_table
    #@messages         = ::Message.where(message_table[:task_id].in(@tasks.select(:id).ast)).includes(:attachments).order('messages.created_at DESC')
    @media_channels = current_user.company.media_channels.to_a
    @agents = current_user.company.try(:agents)
    @current_user_service_channels = current_user.service_channels.to_a
    @current_user_locations = current_user.possible_service_channels

    #raise 'Cannot assign sip credentials to agent who is not in sip media channel! '
    #TODO: FIX this ASAP!

    @sip_settings = current_user.sip_settings || SipSettings.new

    @task = ::Task.new

    message = ::Message.new
    message.attachments << ::Message::Attachment.new

    @task.messages << message

    if current_user.service_channel and current_user.imap_settings.valid?
      @service_channels << current_user.service_channel unless @service_channels.include?(current_user.service_channel)
      @media_channels << current_user.service_channel.email_media_channel unless @media_channels.include?(current_user.service_channel.email_media_channel)
    end
    @task_page = true
  end

  def show
    render json: @task.decorate
  end

  def send_email
    logger.info "===Before====#{params.inspect}==========#{params[:send_email].inspect}======"
    email_recipient = params[:send_email][:recipient].split(',').collect(&:strip).uniq
    email_params = params[:send_email]
    message = email_params[:email_message]
    company_file_ids = email_params[:company_files_ids]

    email_cc = email_params[:cc]
    email_bcc = email_params[:bcc]
    service_channel_id = email_params[:service_channel]

    if service_channel_id == 'agent'
      media_channel = current_user.agent_media_channel
      imap_settings = current_user.imap_settings
    else
      service_channel = ServiceChannel.find(service_channel_id)
      imap_settings = service_channel.email_media_channel.imap_settings
      media_channel = service_channel.email_media_channel
    end
    # email_recipient = email_recipient.join(' ').gsub(imap_settings.try(:from_email), '').split
    email_params[:recipient] = email_recipient.to_sentence(:last_word_connector => ', ', :two_words_connector => ', ')
    logger.info "==After=====#{params.inspect}==========#{params[:send_email].inspect}======"
    mail = Mail.new do
      to email_params[:recipient]
      from imap_settings.from
      subject email_params[:email_subject]
      cc email_cc if email_cc.present?
      bcc email_bcc if email_bcc.present?
      html_part do
        body message
      end
    end

    if company_file_ids.present?
      company_file_ids.each do |id|
        file = current_user.company.files.find_by_id(id)
        if file.present?
          mail.add_file(filename: file.file_name, content: file.file.read)
        end
      end
    end

    if imap_settings.from.blank?
      return render json: { error:  current_user.imap_settings.to_json }, status: 400
    end

    if email_params[:attachments]
      email_params[:attachments].each do |a|
        mail.add_file(filename: a.original_filename, content: a.tempfile.read)
      end
    end

    media_channel.add_sent_email_task(
      mail,
      message,
      assigned_to_user_id: current_user.id
    )

    email_recipient.each do |email|
      user_email = current_user.recepient_emails.find_or_create_by(email: email)
    end
    render json: { success: true }, status: 200
  end

  def create
    task = ::Task.new

    if params[:task][:type] == 'internal'
      params[:task][:media_channel_id] =
        MediaChannel.find_by(service_channel_id: params[:task][:service_channel_id],
                             type: 'MediaChannel::Internal').try(:id)
    elsif params[:task][:type] == 'chat'
      params[:task][:media_channel_id] =
        MediaChannel.find_by(service_channel_id: params[:task][:service_channel_id],
                             type: 'MediaChannel::Chat').try(:id)
    else
      return render :json => {:error => 'Invalid task type'}, status: 400
    end

    media_chan = MediaChannel.find(params[:task][:media_channel_id])

    task.attributes = task_params
    first_message = task.messages.first
    first_message.channel_type = media_chan.class.name.downcase.split('::').last
    task.created_by_user_id = current_user.id

    if agent = current_user.company.users.find_by(id: params[:task][:assigned_to_user_id])
      first_message.to = agent.email
    elsif params[:chat]
      first_message.to = current_user.email
    else
      first_message.to = 'Internal'
    end

    if params[:task][:type] == 'chat' && params[:chat] && params[:chat][:from].present?
      first_message.from = params[:chat][:from]
    elsif params[:task][:type] == 'chat' && params[:chat] && params[:chat][:from].blank?
      first_message.from = 'Anonymous'
    elsif params[:task][:type] == 'chat' && params[:task][:messages_attributes].fetch("0", {})[:from].blank?
      first_message.from = current_user.email
    elsif params[:task][:type] == 'chat' &&
      first_message.from = params[:task][:messages_attributes].fetch("0", {})[:from]
    end

    if params[:task][:type] == 'internal'
      first_message.from = current_user.email
      first_message.to = 'Internal'
      first_message.is_internal = true
    end


    first_message.user_id = current_user.id

    params[:task][:messages_attributes].fetch("0", {}).fetch(:attachments, []).each do |file|
      file_params = {file: file, file_name: file.original_filename, content_type: file.content_type, file_size: file.size}
      # if (file.original_filename === "contakti-recording.wav")
      if (file.original_filename.downcase.starts_with?("contakti-recording"))
        file_params["is_call_recording"] = true
        first_message.attachments.build(file_params)
      else
        first_message.attachments.build(file_params)
      end
    end

    if params["company_files_ids"].present?
      params["company_files_ids"].each do |id|
        company_file = CompanyFile.find_by_id(id)
        if company_file.present?
          first_message.attachments.build(
            file: company_file,
            file_name: company_file.file_name,
            file_size: company_file.file_size,
            content_type: company_file.file_type,
          )
        end
      end
    end


    task.customer = Customer.find_by_email_or_phone(
      params[:chat][:from],
      params[:chat][:from_phone],
      media_chan.company.id
    )

    if params[:chat] && params[:task][:chat_attachments].present?
      params[:task][:chat_attachments].each do |attachment_path|
        next if attachment_path.blank?
        path = "#{Rails.root}/public/chatuploads/#{attachment_path}"

        first_message.attachments.build(
          file_name: File.basename(path),
          file_size: File.size(path),
          content_type: 'application/octet-stream',
          file: File.open(path)
        )
      end
    end

    task.dont_push_to_browser = true
    if task.save
      task.dont_push_to_browser = false
      task.skill_list = ""
      task.generic_tag_list = ""
      if params[:tags].present?
        company_skill_list = current_user.company.skill_list
        params[:tags].split(',').map(&:strip).uniq.each do |tag|
          if company_skill_list.include?(tag)
            task.skill_list.add(tag)
          else
            task.generic_tag_list.add(tag)
          end
        end
      end

      wit_response = post_to_wit_api(task)
      task.save

      max_skill_priority_object = task.max_skill_priority_object
      if max_skill_priority_object.present?
        time = max_skill_priority_object.expire_time
        if time.present? && time >= 0
          UpdateOpenTaskWorker.perform_in(time.minutes,task.id)
        end
      else
        UpdateOpenTaskWorker.perform_in(5.seconds,task.id)
      end
      if params[:chat]
        first_message = task.messages.first
        first_message.add_signature_to_description
        first_message.save
      end
      render json: ::DanthesService.new(task.reload).json_for_push_to_browser[:task].to_json
    else
      render json: {ok: false, errors: task.errors}, status: :unprocessable_entity
    end
  end

  def get_tasks
    set_user_online
    @tasks = current_user_tasks
    Oj.default_options = {mode: :compat}
    render json: Oj.dump(ActiveModel::ArraySerializer.new(@tasks.decorate, each_serializer: ExtendedTaskSerializer))
  end

  def get_ready_tasks
    if params[:offset]
      @tasks = current_user_ready_tasks params[:offset]
    else
      @tasks = current_user_ready_tasks 0
    end

    message_table = ::Message.arel_table
    @messages = ::Message.where(message_table[:task_id].in(@tasks.select(:id).ast)).includes(:attachments).order('messages.created_at DESC')
    Oj.default_options = {mode: :compat}
    render json: Oj.dump(ActiveModel::ArraySerializer.new(@tasks.decorate, each_serializer: ExtendedTaskSerializer))
  end

  def call_history
    @call_history = current_user.call_histories.order(created_at: :desc)
    logger.info "===call history========#{@call_history.inspect}=============="
    render json: @call_history
  end

  def add_call_history
    logger.info "=====add_call_history===========#{params.inspect}========#{current_user.inspect}=="
    @call_history = current_user.call_histories.new(remote: params[:remote], incoming: params[:incoming], duration: params[:duration])
    if @call_history.save
      render json: @call_history
    else
      render json: {ok: false}, status: :unprocessable_entity
    end
  end

  def get_task_by_id
    if params[:q].blank?
      render json: {ok: false, errors: "Parameter is empty"}
      return
    end
    logger.info "=========TASKS CONTROLLER USED=========get_task_by_id"
    task ||= ::Task.accessible_by(current_ability).

      eager_load(:agent,
                 :service_channel,
                 :media_channel,
                 messages: [:task, :attachments],
                 service_channel: [{locations: [weekly_schedule: [:schedule_entries]]}, weekly_schedule: :schedule_entries],
                 media_channel: [weekly_schedule: :schedule_entries]

      ).preload(:note).where(id: params[:q]).order('tasks.created_at DESC')

    message_table = ::Message.arel_table
    @messages = ::Message.where(message_table[:task_id].in(task.select(:id).ast)).includes(:attachments).order('messages.created_at DESC')
    Oj.default_options = {mode: :compat}
    render json: Oj.dump(ActiveModel::ArraySerializer.new(task.decorate, each_serializer: ExtendedTaskSerializer))
  end

  def change_state
    event = params[:event] if @task.aasm.events.map {|t| t.name.to_s}.include?(params[:event])
    logger.info "====event==========#{event.inspect}===================================="
    return render :json => {}, status: 200 if event.nil?

    logger.info "====task==========#{@task.inspect}===================================="
    @task.__send__(event)

    logger.info "====task=status========================#{@task.state.inspect}=================="
    @task.assigned_to_user_id = if @task.state == 'new'
                                  nil
                                else
                                  current_user.id
                                end
    @task.closed_by_user = current_user if @task.state == 'ready'
    @task.result = params[:result] if params[:result]
    logger.info "=latest===task=status========================#{@task.inspect}=================="
    if @task.save
      @task.push_task_to_browser
      render json: ::DanthesService.new(@task).json_for_push_to_browser[:task].to_json
    else
      logger.info "Task errors: #{@task.errors.full_messages}"
      render json: {ok: false}, status: :unprocessable_entity
    end
  end

  def save_draft
    unless params[:description].blank?
      @task.build_draft unless @task.draft
      @task.draft.description = params[:description].to_s
      @task.save!
    end

    render json: { success: true }, status: 200
  end

  def refresh_waiting_timeout
    if @task.refresh_waiting_timeout
      render json: ::DanthesService.new(@task).json_for_push_to_browser[:task].to_json
    else
      logger.info "Task errors: #{@task.errors.full_messages}"
      render json: {ok: false}, status: :unprocessable_entity
    end
  end

  def manage
    # Perhaps not the most super way to cancel form changes to clients in-memory task instance.
    if params[:cancel].to_s == "1"
      @task.push_task_to_browser
      return render json: {ok: true}
    end

    if params[:agent_id].present?
      @task.agent = User.find(params[:agent_id])

      if @task.agent != current_user && !@task.new?
        @task.renew
      end
    elsif params[:service_channel_id].present?
      @task.agent = nil
      @task.service_channel = ServiceChannel.find(params[:service_channel_id])

      media_channel_type =
        "#{MediaChannel.get_channel_type_by_classname(@task.media_channel.type)}_media_channel"
      @task.media_channel = @task.service_channel.public_send(media_channel_type)
    end

    existing_task_tags = @task.skill_list | @task.generic_tag_list
    @task.skill_list = ""
    @task.generic_tag_list = ""
    if params[:tags].present?
      company_skill_list = current_user.company.skill_list
      params[:tags].split(',').map(&:strip).uniq.each do |tag|
        if company_skill_list.include?(tag)
          @task.skill_list.add(tag)
          ::PriorityAlarmWorker.perform_async(tag, @task.id, current_user.company_id) if existing_task_tags.exclude?(tag)
        else
          @task.generic_tag_list.add(tag)
          ::PriorityAlarmWorker.perform_async(tag, @task.id, current_user.company_id) if existing_task_tags.exclude?(tag)
        end
      end
    end

    if params[:urgency].to_s == "urgent"
      @task.flag_list.add("urgent")
    else
      @task.flag_list.remove("urgent")
    end

    if @task.save
      apply_task_priority(@task.id, existing_task_tags)
      render json: {ok: true}
    else
      render json: {ok: false}
    end
  end

  def send_chat_history
  end

  def update
    if params[:reply][:internal] == "true"
      if !@task.service_channel.email_media_channel or !@task.service_channel.email_media_channel.active or !@task.media_channel.smtp_settings
        return render json: {}, status: :unprocessable_entity
      end
    end
    logger.info "====update params=====#{params.inspect}========"
    reply = @task_service.reply_from(current_user)
    logger.info "====update reply=====#{reply.inspect}========"
    logger.info "====before task =====#{@task.inspect}========"
    # if reply[:ok] && @task.state == 'ready'
    #   @task.update(state: 'open')
    # end
    logger.info "====after task =====#{@task.inspect}========"
    if reply[:ok]
      @task.draft.destroy if @task.draft
      respond_to do |format|
        format.html do
          flash[:notice] = "Reply sent to #{reply[:data].to}"
          redirect_to action: :index
        end
        format.js do
          @data = ::DanthesService.new(reply[:data]).json_for_push_to_browser.to_json
          if reply[:data].sms?
            @status_message = I18n.t('user_dashboard.user_dashboard_mailer.sms_sent_to') + " #{reply[:data].to}"
          else
            @status_message = I18n.t('user_dashboard.user_dashboard_mailer.msg_sent_to') + " #{reply[:data].to}"
          end
        end
      end
    else
      render json: reply.to_json, status: :unprocessable_entity
    end
  end

  def destroy
    @task = ::Task.accessible_by(current_ability, :manage).where(id: params[:id]).first
    if @task.destroy
      respond_to do |format|
        format.html do
          redirect_to action: :index
        end
        format.js do
          render json: {ok: 'true'}, status: 204
        end
      end
    else
      respond_to do |format|
        format.html do
          redirect_to action: :index, notice: 'Could not delete task'
        end
        format.js do
          render json: {ok: false}, status: 400
        end
      end
    end
  end

  def note
    if params[:note][:body].blank?
      @task.note.destroy if @task.note
      note = @task.build_note
    else
      puts "*********************************************************************"
      @task.build_note unless @task.note
      @task.note.body = params[:note][:body]
      # params[:task][:messages_attributes].fetch("0", {}).fetch(:attachments, []).each do |a|
      #   first_message.attachments.build(file: a, file_name: a.original_filename, content_type: a.content_type, file_size: a.size)
      # end
      if params[:attachments].present?
        params[:attachments].each do |a|
          @task.note.attachments.build(file: a, file_name: a.original_filename, content_type: a.content_type, file_size: a.size)
          @task.note.save!
          @task.note.attachments.build(file: a, file_name: a.original_filename, content_type: a.content_type, file_size: a.size)
        end
      end
      # @task.note.attachments.create(params[:attachments])
      @task.save!
      note = @task.note
    end
    @task.push_task_to_browser
    render json: note
  end

  def danthes_subscribe
    channel = "/media_channels/#{params[:channel_id]}/tasks"
    channel.concat('/').concat(params[:sub_channel]) if params[:sub_channel]
    render json: ::Danthes.subscription(channel: channel)
  end

  def danthes_bulk_subscribe
    response = []
    current_user.company.media_channels.pluck(:id).each do |channel_id|
      ['addNewMessage', 'alertWaitingTaskTimeout'].each do |sub_channel|
        channel = "/media_channels/#{channel_id}/tasks"
        channel.concat('/').concat(sub_channel) if sub_channel == 'alertWaitingTaskTimeout'
        response << {item: sub_channel, sub: ::Danthes.subscription(channel: channel)}
      end
    end
    render json: response.to_json
  end

  def subscribe_agents
    channel = '/company/' + current_user.company.id.to_s + '/online'
    render json: ::Danthes.subscription(channel: channel)
  end

  def search_agents
    sc = current_user.company.service_channels.where(id: ServiceChannel.find(params[:sc])).first

    if params[:q].blank?
      @q = sc.users.where("users.is_online IS TRUE AND users.id != ?", current_user.id).where('? = ANY(media_channel_types)', 'chat')
    else
      @q = sc.users.where("users.is_online IS TRUE AND users.id != ? AND first_name || ' ' || last_name || ' ' || title ILIKE ?", current_user.id, "%#{params[:q]}%").where('? = ANY(media_channel_types)', 'chat')
    end

    render json: @q
  end

  def get_agents_by_service_channel_id
    service_channel_id = Integer(params[:q]) # Check if it number and raise error if not
    @q = ::User.joins(:service_channels).ransack(service_channels_id_eq: service_channel_id)
    render json: @q.result.pluck(:email)
  end

  def get_all_service_channels
    service_channels = current_user.service_channels
    service_channels = service_channels.reject {|sc| sc.email_media_channel.nil? || sc.email_media_channel.broken}
    render json: service_channels.collect { |sc| [sc.id, sc.name, sc.signature] }
  end

  def search
    @q = ::Task.accessible_by(current_ability).joins(:service_channel).joins(:messages).ransack(m: 'or', service_channel_name_cont: params[:q], messages_search_cond_cont: params[:q], data_search_cont: params[:q])
    render json: @q.result.pluck(:id)
  end

  def super_search
    searchResult = []
    # @q = prepare_search_queue("all")
    #
    # # Search tasks
    # task_results = @q.result.limit(10)
    # distincted_task_results = []
    # # Workaround for removing duplicates. There is an issue with distinct, uniq and Postgre
    # task_results.each do |task|
    #   should_add = true
    #   distincted_task_results.each do |dist_task_result|
    #     if dist_task_result.id == task.id
    #       should_add = false
    #     end
    #   end
    #   if should_add
    #     distincted_task_results << task
    #   end
    # end
    # distincted_task_results = distincted_task_results.as_json
    # searchResult.push(*distincted_task_results)

    # Search Customers
    customers_query = ::Customer.ransack(
      m: 'or',
      first_name_cont: params[:q],
      # last_name_cont: params[:q],
      # person_email_cont: params[:q],
      # person_phone_cont: params[:q],
      contact_phone_cont: params[:q],
      contact_email_cont: params[:q],
      # contact_website_cont: params[:q],
      # contact_facebook_cont: params[:q],
      # contact_twitter_cont: params[:q],
      # contact_skype_cont: params[:q],
      name_cont: params[:q],
    # address_cont: params[:q],
    # city_cont: params[:q],
    # country_cont: params[:q],
    # vat_cont: params[:q],
    # postcode_cont: params[:q],
    )
    customers_query.sorts = ['name asc']
    customers_results = customers_query.result.where(company_id: current_user.company_id).limit(5).offset(params[:offset])

    customers_results.each do |customer_result|
      customer_result.result_type = "customer"
      searchResult.push(customer_result.as_json(
        methods: [:result_type],
      # :include => {:customer_company => {:only => [:name, :id]}}
      ))
    end
    #
    # # Search Companies
    # company_results = ::CustomerCompany.ransack(
    #   m: 'or',
    #   name_cont: params[:q],
    #   code_cont: params[:q]).result.limit(5)
    #
    # company_results.each do |company_result|
    #   company_result.result_type = "company"
    #   searchResult.push(company_result.as_json(
    #     methods: [:result_type],
    #     :include => {:contact_person => {:only => [:id, :first_name, :last_name, :email]}}))
    # end

    render json: searchResult
    # render json: @q.result(distinct: true).pluck(:id)
  end

  def search_unsolved
    @q = prepare_search_queue("unsolved")
    render json: @q.result.limit(5).as_json(:include => {:creator => {:only => [:id, :first_name, :last_name]}})
    # render json: @q.result(distinct: true).pluck(:id)
  end

  def search_archived
    @q = prepare_search_queue("archived")
    render json: @q.result.limit(5).as_json(:include => {:creator => {:only => [:id, :first_name, :last_name]}})
  end

  def get_customer_tasks
    logger.info "=========TASKS CONTROLLER USED=========get_customer_tasks"
    @tasks = Task.eager_load(
      :skills,
      :generic_tags,
      :flags,
      :agent,
      :service_channel,
      :media_channel,
      messages: [:task, :attachments],
      service_channel: [{locations: [weekly_schedule: [:schedule_entries]]}, weekly_schedule: :schedule_entries],
      media_channel: [weekly_schedule: :schedule_entries]

    ).preload(:note)
      .where(customer_id: params[:customer_id])
      .where.not(state: [:archived, :ready])
      .order('tasks.created_at DESC').limit(30).offset(params[:offset])

    Oj.default_options = {mode: :compat}
    render json: Oj.dump(ActiveModel::ArraySerializer.new(@tasks.decorate, each_serializer: CustomerTaskSerializer))
  end

  def get_customer_ready_tasks
    logger.info "=========TASKS CONTROLLER USED=========get_customer_ready_tasks"
    @tasks = Task.eager_load(
      :agent,
      :service_channel,
      :media_channel,
      messages: [:task, :attachments],
      service_channel: [{locations: [weekly_schedule: [:schedule_entries]]}, weekly_schedule: :schedule_entries],
      media_channel: [weekly_schedule: :schedule_entries]

    ).preload(:note)
      .where(customer_id: params[:customer_id])
      .where(state: :ready)
      .order('tasks.created_at DESC').limit(30).offset(params[:offset])

    Oj.default_options = {mode: :compat}
    render json: Oj.dump(ActiveModel::ArraySerializer.new(@tasks.decorate, each_serializer: CustomerTaskSerializer))
  end

  def current_user_tasks
    tasks_ids = define_tasks
    logger.info "==========CURRENT USER TASKS #{tasks_ids}=========="
    #::Task.accessible_by(current_ability)
    #logger.info "=========TASKS CONTROLLER USED=========current_user_tasks"
    @current_user_tasks ||= ::Task.accessible_by(current_ability)
      .eager_load(
        :skills,
        :generic_tags,
        :flags,
        :agent,
        :service_channel,
        :media_channel,
        messages: [:task, :attachments],
        service_channel: [{locations: [weekly_schedule: [:schedule_entries]]}, weekly_schedule: :schedule_entries],
        media_channel: [weekly_schedule: :schedule_entries]
      ).preload(:note)
      .where(id: tasks_ids)
      .where.not(state: [:archived, :ready])
      .order('tasks.created_at DESC')
  end

  def current_user_ready_tasks (offset)
    tasks_ids = define_tasks
    logger.info "==========CURRENT USER TASKS #{tasks_ids}=========="
    #logger.info "=========TASKS CONTROLLER USED=========current_user_ready_tasks"
    @current_user_ready_tasks ||= ::Task.accessible_by(current_ability).

      eager_load(:skills,
                 :generic_tags,
                 :flags,
                 :agent,
                 :service_channel,
                 :media_channel,
                 messages: [:task, :attachments],
                 service_channel: [{locations: [weekly_schedule: [:schedule_entries]]}, weekly_schedule: :schedule_entries],
                 media_channel: [weekly_schedule: :schedule_entries]
      ).preload(:note)
      .where(state: :ready, id: tasks_ids)
      .order('tasks.created_at DESC').limit(30).offset(offset)
  end

  def change_service_channel
    @service_channel = current_user.service_channels.where(id: params[:channel_id]).first
    if @task && @service_channel
      @task.change_service_channel(@service_channel)
      render json: @task.decorate
    else
      render json: {ok: false}, status: :unprocessable_entity
    end
  end

  def assign_to_agent
    @agent = current_user.company.users.where(id: params[:agent_id]).first
    if @task
      @task.assign_to_agent(@agent)
      render json: @task.decorate
    else
      render json: {ok: false}, status: :unprocessable_entity
    end
  end

  def load_task_by_id
    #@task = ::Task.accessible_by(current_ability).where(id: params[:id]).first
    @task = ::Task.accessible_by(current_ability).find_by(id: params[:id])
    if params[:reply] && params[:reply][:is_sms].present?
      @task.send_by_user = current_user;
      @task.save
    end
    unless @task
      #task = current_user.company.tasks.where(id: params[:id]).first
      task = current_user.company.tasks.find_by(id: params[:id])
      if params[:reply] && params[:reply][:is_sms].present?
        task.send_by_user = current_user;
        task.save
      end
      render(json: ::DanthesService.new(task).json_for_push_to_browser.to_json, status: :method_not_allowed) && return
    end
    @task_service = ::TaskService.new(@task, params)
  end

  def load_task_for_manage
    @task = ::Task.find_by(id: params[:id])
    #@task = ::Task.where(id: params[:id]).first
    unless @task
      task = current_user.company.tasks.where(id: params[:id]).first
      render(json: ::DanthesService.new(task).json_for_push_to_browser.to_json, status: :method_not_allowed) && return
    end
    @task_service = ::TaskService.new(@task, params)
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
    @tasks = current_user_tasks
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

  def follow_task
    @task.follows.build(task_id: @task.id, user_id: current_user.id)
    @task.save
    @task.push_task_to_browser
    render json: ::DanthesService.new(@task).json_for_push_to_browser[:task].to_json
  end

  def unfollow_task
    follow = ::Follow.where(task_id: @task.id, user_id: current_user.id).first
    follow.destroy if follow
    task = ::Task.find(@task.id)
    task.push_task_to_browser
    render json: ::DanthesService.new(task).json_for_push_to_browser[:task].to_json
  end

  def get_all_agents
    response = []
    if current_user.has_role? :agent
      @q                = current_user.company.agents.ransack
      @q.sorts          = 'full_name_format asc'
      @agents = @q.result(distinct: false)
      response = @agents.as_json(only: [:is_online, :in_call, :id, :title], methods: [:full_name_format, :full_name, :sip_user_name])
    end
    render json: response
  end

  def subscribe_to_agents_in_call_status
    response = []

    if current_user.has_role? :agent
      current_user.company.agents.each do |agent|
        channel = "/in_call_status/#{agent.id}"
        response << ::Danthes.subscription(channel: channel)
      end
    end
    render json: response.to_json
  end

  def change_in_call_status
    in_call = params[:in_call] == 'true'
    set_user_in_call(in_call)
    render :nothing => true
  end

  def mark_message_as_read
    task_id = params[:id]
    render json: ::MarkEmailAsReadWorker.perform_async(task_id)
  end

  private

  def set_common_variables
    print service_channels_collection.any? ? service_channels_collection.first[2] : [],"service_channels_collectionservice_channels_collection"
    # @service_channels = current_user.service_channels
    @service_channels = current_user.company.service_channels
    @service_channel = ServiceChannel.includes(:locations).where(
      id: @service_channels.first.id
    ).first
    @sms_template = ::SmsTemplate.new

    @sms_templates = @service_channel.agent_sms_templates
    gon.sms_templates = @sms_templates
    @manager_template = ::SmsTemplate.new
    if @sms_template.for_agent?
      @sms_templates        = @service_channel.agent_sms_templates
      gon.sms_templates     = @sms_templates
    else
      @manager_template     = @sms_template
      @manager_templates    = ::SmsTemplate.for_manager.accessible_by(current_ability)
      gon.manager_templates = @manager_templates
    end
  end

  def set_user_online
    current_user.agent_in_call_status_notifier
    if not current_user.is_online?
      current_user.set_online true
      ::Danthes.publish_to "/users_online/#{current_user.id.to_s}", {:online => true}
    end
  end

  def set_user_in_call(status)
    current_user.set_in_call status
    current_user.agent_in_call_status_notifier
  end

  def prepare_search_queue(mode)
    queue = ::Task.accessible_by(current_ability)
    if mode.eql? "archived"
      queue = queue.archived
    elsif mode.eql? "unsolved"
      queue = queue.unsolved
    end

    queue.joins(:service_channel).joins(:messages).joins(:agent).ransack(
      m: 'or',
      state_cont: params[:q],
      service_channel_name_cont_any: params[:q],
      messages_search_cond_cont_any: params[:q],
      data_search_cont_any: params[:q],
      agent_first_name_cont_any: params[:q],
      agent_last_name_cont_any: params[:q])
  end

  def task_params
    @task_params ||= params.require(:task).permit(
      :media_channel_id,
      :service_channel_id,
      :assigned_to_user_id,
      :email_to_addresses,
      :email_subject,
      :email_message,
      :email_lang,
      :skills,
      :flags,
      :campaign_item_id,
      :is_softfone_ticket,
      messages_attributes: messages_attributes
    )
  end

  def messages_attributes
    @messages_params ||= [
      :description,
      :title,
      :channel_type,
      :from,
      :to,
      :is_internal,
#        attachments: []
    ]
  end

  def sms_template_params
    @sms_template_params ||= params[:sms_template].permit(:kind, :title, :text, :service_channel_id, :visibility, :location_id)
  end

  def load_sms_template
    begin
      id = params[:sms_template][:id]
      @sms_template = id.present? && params[:sms_template][:save_as_new] != 'true' ? ::SmsTemplate.find(id) : ::SmsTemplate.new

      if params[:sms_template][:save_as_new] == 'false' && id.blank? && params[:sms_template][:title].present?
        @sms_template = ::SmsTemplate.where(
          title: params[:sms_template][:title]
        ).where(
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

  def apply_task_priority(task_id, existing_task_tags)
    updated_task = ::Task.find(task_id)
    new_tags = (updated_task.skill_list | updated_task.generic_tag_list) - existing_task_tags
    if new_tags.any? && updated_task.task_priority && !updated_task.assigned_to_user_id
      updated_task.update_attributes(open_to_all: false)
      time = Priority.find_by(priority_value: updated_task.task_priority, tag_id: updated_task.skills.map(&:id), company_id: current_user.company_id).expire_time
      UpdateOpenTaskWorker.perform_in(time.minutes, task_id)
      ::DanthesService.new(updated_task).push_to_browser
    end
  end

  def define_tasks
    @user = current_user
    channel_ids = ::MediaChannel.joins(:service_channel => :users)
                                .where('service_channels.company_id' => @user.company_id)
                                .where(service_channels_users: { user_id: @user.id})
                                .where(type: @user.media_channel_types.map { |c| ::MediaChannel.get_classname_by_channel_type(c) })
                                .where(active: true)
                                .select(:id).to_a

    combined_channel_ids = channel_ids.collect(&:id)

    if @user.service_channel and @user.service_channel.email_media_channel
      combined_channel_ids << @user.service_channel.email_media_channel.id
    end
    combined_channel_ids << 386

    arel_table = Task.arel_table
    open_to_all = arel_table[:state].in(%w(open))
      .and(arel_table[:assigned_to_user_id].eq(nil))
      .and(arel_table[:media_channel_id].in(combined_channel_ids))

    user_skills = @user.user_skills

    all_tasks = Task.eager_load(:skills).where(service_channel_id: @user.company.service_channels.ids)
    task_with_high_priority = all_tasks.select { |rec| rec.custom_task_priority(rec.skills) == 3 && rec.open_to_all == true }
    medium_priority_tasks = all_tasks.select { |task| task.custom_task_priority(task.skills) == 2 && task.open_to_all == true && task.service_channel_agent_ids.include?(@user.id) }
    low_priority_tasks = all_tasks.select { |task| task.custom_task_priority(task.skills).in?([1, 2]) && task.open_to_all == true && task.skills_matched_service_channel_agents(task.skills).present? }
  
    allowed_low_priority_task_ids = []
    disallowed_low_priority_task_ids = []

    low_priority_tasks.select{|task| task.skills_matched_service_channel_agents(task.skills).include?(@user.id) ? allowed_low_priority_task_ids << task.id : disallowed_low_priority_task_ids << task.id }
    assigned_to_current_agent = []
    assigned_to_other_agent = []

    all_tasks.select { |task| (task.assigned_to_user_id == @user.id) ? assigned_to_current_agent << task.id : assigned_to_other_agent << task.id if (task.assigned_to_user_id.present? && task.state != 'ready') }

    channel_skill_based_task_ids = all_tasks.select { |task| task.custom_task_priority(task.skills).in?([1, 2, 3]) && task.open_to_all == false && task.skills_matched_service_channel_agents(task.skills).include?(@user.id) }.collect(&:id)
    channel_skill_based_task_ids = []
    tasks = Task.eager_load(:skills).where( arel_table[:media_channel_id]
                          .in(combined_channel_ids)
                          .and(arel_table[:state].in(%w(new ready)))
                          .or(arel_table[:assigned_to_user_id].eq(@user.id))
                          .or(open_to_all) )

    priotiy_task_ids = tasks.select{ |task| task.custom_task_priority(task.skills).in?([1, 2, 3]) && task.open_to_all == false && (user_skills & task.skills.collect(&:name)).blank? }.collect(&:id)
    total_task = tasks + task_with_high_priority + medium_priority_tasks

    priotiy_task_ids = priotiy_task_ids - channel_skill_based_task_ids

    tasks = Task.where(id: (total_task.map(&:id) + channel_skill_based_task_ids + allowed_low_priority_task_ids + assigned_to_current_agent + assigned_to_other_agent - ((priotiy_task_ids + disallowed_low_priority_task_ids) - assigned_to_current_agent)))
    tasks.ids
  end
end
