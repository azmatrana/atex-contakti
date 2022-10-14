class Api::V1::TasksController < Api::V1::BaseController
  include TasksHelper
  before_action :check_agent_access, except: [:create_task_from_chat]
  before_action :load_task_by_id, only: [:update, :reply, :destroy, :change_task_state]

  def index
    @tasks = ::Task.accessible_by(current_ability)
        .eager_load(:agent,
                   :service_channel,
                   :media_channel,
                   messages:        [:task, :attachments],
                   service_channel: [{locations: [weekly_schedule: [:schedule_entries]]}, weekly_schedule: :schedule_entries],
                   media_channel: [weekly_schedule: :schedule_entries]
        ).preload(:note)
                 .where.not(state: [:archived, :ready])
                 .order('tasks.created_at DESC')

    message_table      = ::Message.arel_table
    @messages          = ::Message.where(message_table[:task_id].in(@tasks.select(:id).ast)).includes(:attachments).order('messages.created_at DESC')
    Oj.default_options = {mode: :compat}

    render json: Oj.dump(ActiveModel::ArraySerializer.new(@tasks.decorate, each_serializer: ExtendedTaskSerializer))
  end

  def create
    if params[:is_mobile]
      new_params(params)
    end
    task = ::Task.new
    if params[:type] == 'internal'
      params[:media_channel_id] = current_user.media_channels
        .where(:service_channel_id => params[:service_channel_id], :type => "MediaChannel::Internal").first.id
    elsif params[:type] == 'chat'
      params[:media_channel_id] = current_user.media_channels
        .where(:service_channel_id => params[:service_channel_id], :type => "MediaChannel::Chat").first.id
    else
      return render :json => {:error => "Invalid task type"}, status: 400
    end

    media_chan = MediaChannel.find(params[:media_channel_id])

    task.attributes = task_params
    first_message = task.messages.first
    first_message.channel_type = media_chan.class.name.downcase.split('::').last
    task.created_by_user_id = current_user.id

    media_chan = MediaChannel.find(params[:media_channel_id])
    if agent = media_chan.users.where(id: params[:assigned_to_user_id]).first
      first_message.to = agent.email
    else
      first_message.to = "Internal"
    end

    if params[:messages_attributes].fetch("0", {})[:from].blank?
      first_message.from = current_user.email
    else
      first_message.from = params[:messages_attributes].fetch("0", {})[:from]
    end

    first_message.user_id = current_user.id
    first_message.is_internal = true if params[:type] == 'internal'

    params[:messages_attributes].fetch("0", {}).fetch(:attachments, []).each do |a|
      first_message.attachments.build(file: a, file_name: a.original_filename, content_type: a.content_type, file_size: a.size)
    end
    if params[:attachments]
      params[:attachments].each do |a|
        first_message.attachments.build(file: a, file_name: a.original_filename, content_type: a.content_type, file_size: a.size)
      end
    end
    if task.save
      render json: ::DanthesService.new(task).json_for_push_to_browser[:task].to_json
    else
      render json: { ok: false, errors: task.errors }, status: :unprocessable_entity
    end
  end

  def create_task_from_chat
    channel_id = params[:channel_id]
    record = ChatRecord.where(channel_id: channel_id).first
    if record && record.user_quit != true
      task = ::Task.new
      params[:service_channel_id] = ::MediaChannel.find(params[:media_channel_id]).service_channel.id
      task.attributes = task_params

      first_message = task.messages.first
      if (first_message.present? && params[:user_uploaded_file_urls].present? && params[:user_uploaded_file_urls].length > 0)
        file_urls = params[:user_uploaded_file_urls]
        file_urls.each do |file_url|
          file_path = file_url.gsub(Settings.host_origin, '')
          file = File.open(Rails.root.join("public/#{file_path}"))
          file_name = file_path.split('/')[-1]
          content_type = 'application/octet-stream'
          file_size = file.size
          first_message.attachments.build(file: file, file_name: file_name, content_type: content_type, file_size: file_size)
        end
      end

      if task.save
        first_message = task.messages.first
        first_message.add_signature_to_description
        first_message.save
        wit_response = post_to_wit_api(task)
        task.save
        render json: ::DanthesService.new(task).json_for_push_to_browser[:task].to_json
      else
        render json: { ok: false, errors: task.errors }, status: :unprocessable_entity
      end
    else
      render json: {ok: false}, status: 401
    end
  end

  def new_params(params)
    params['type'] = 'internal'
    params['service_channel_id'] = params[:new_task_service_channel]
    params['agent_id'] = params[:new_task_agent_id]
    params[:messages_attributes] = {}
    params[:messages_attributes]["0"] = {:title => params[:new_task_title], :description => params[:new_task_description]}
    params.except(:new_task_service_channel,:new_task_agent_id,:new_task_title, :new_task_description)
  end

  def note
    @task = Task.find(params[:id])
    if params[:note][:body].blank?
      @task.note.destroy if @task.note
      note = @task.build_note
    else
      @task.build_note unless @task.note
      @task.note.body = params[:note][:body]
      @task.save!
      note = @task.note
    end
    @task.push_task_to_browser
    render json: note
  end

  def update
    if params[:update_action] == 'change_state'
      change_state
    end
    if params[:update_action] == 'update_settings'
      update_settings
    end

    if params[:update_action] == 'follow_task'
      follow_task
    end

    if params[:update_action] == 'unfollow_task'
      unfollow_task
    end

    if @task.save!
      render json: ::DanthesService.new(@task).json_for_push_to_browser[:task].to_json
    else
      logger.info "Task errors: #{@task.errors.full_messages}"
      render json: { ok: false }, status: :unprocessable_entity
    end
  end

  def reply
    reply = @task_service.reply_from(current_user)
    if reply[:ok]
      render json: ::DanthesService.new(reply[:data]).json_for_push_to_browser.to_json
    else
      render json: reply.to_json, status: :unprocessable_entity
    end
  end

  def get_ready_tasks
    if params[:offset]
      @tasks = current_user_ready_tasks params[:offset]
    else
      @tasks = current_user_ready_tasks 0
    end

    message_table = ::Message.arel_table
    @messages     = ::Message.where(message_table[:task_id].in(@tasks.select(:id).ast)).includes(:attachments).order('messages.created_at DESC')
    Oj.default_options = {mode: :compat}

    render json: Oj.dump(ActiveModel::ArraySerializer.new(@tasks.decorate, each_serializer: ExtendedTaskSerializer))
  end

  def danthes_subscribe
    channel = "/media_channels/#{params[:channel_id]}/tasks"
    render json: ::Danthes.subscription(channel: channel)
  end

  def danthes_bulk_subscribe
    response = []
    current_user.company.media_channels.pluck(:id).each do |channel_id|
      channel = "/media_channels/#{channel_id}/tasks"
      response << ::Danthes.subscription(channel: channel)
    end
    render json: response.to_json
  end

  def send_email
    subject = params[:subject]
    message = params[:message]
    email_lang = params[:language]
    recipient = params[:recipient]
    email_cc = params[:cc]
    email_bcc = params[:bcc]
    service_channel_id = params[:service_channel_id]
    settings = nil
    service_channel = nil
    media_channel = nil
    if service_channel_id == 'agent'
      settings = current_user.smtp_settings
      imap_settings = current_user.imap_settings
    else
      service_channel = ServiceChannel.find(service_channel_id)
      media_channel = service_channel.email_media_channel
      settings = service_channel.email_media_channel.smtp_settings
      imap_settings = service_channel.email_media_channel.imap_settings
    end

    smtp_settings = {
      address:        settings.server_name,
      port:           settings.port,
      enable_ssl:     settings.use_ssl?,
      authentication: settings.get_auth_method
    }
    smtp_settings[:user_name] = settings.user_name unless settings.user_name.blank?
    smtp_settings[:password] = settings.password unless settings.password.blank?

    delivery_handler ||= ::Mail::SMTP.new(smtp_settings)
    delivery_handler.settings[:openssl_verify_mode] = "none"


    # TODO: REFACTOR

    task = ::Task.new(
      service_channel_id: service_channel_id
    )

    if media_channel.nil?
      media_channel = current_user.media_channels
        .where(service_channel_id: service_channel_id, type: "MediaChannel::Email").first
    end
    task.media_channel = media_channel

    task.email_subject = subject
    task.email_message = message

    task.created_by_user_id = current_user.id
    task.open
    if task.save

      first_message = task.messages.build
      first_message.channel_type = media_channel.class.name.downcase.split('::').last
      first_message.title = subject
      first_message.description = message
      first_message.to = recipient
      first_message.from = imap_settings.from
      first_message.user_id = current_user.id
      first_message.task_id = task.id
      if params[:attachments]
        params[:attachments].each do |a|
          first_message.attachments.build(file: a, file_name: a.original_filename, content_type: a.content_type, file_size: a.size)
        end
      end
      first_message.save
      first_message.add_signature_to_description
      first_message.need_push_to_browser = true
      first_message.save
      mail = Mail.new do
        to recipient
        from imap_settings.from
        subject subject
        cc email_cc if email_cc
        bcc email_bcc if email_bcc
        html_part do
          body first_message.description
        end
      end
      if params[:attachments]
        params[:attachments].each do |a|
          mail.add_file(:filename => a.original_filename, :content => a.tempfile.read)
        end
      end
      delivery_handler.deliver!(mail)
      return render :json => { success: true }, status: 200
    else
      render json: { ok: false, errors: task.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    if @task.destroy
      return render :json => { success: true }, status: 200
    else
      render json: { ok: false, errors: task.errors }, status: :unprocessable_entity
    end
  end

  def change_task_state
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

  private

  def follow_task
    ::Follow.create(task_id: @task.id, user_id: current_user.id)
  end

  def unfollow_task
    follow = ::Follow.where(task_id: @task.id, user_id: current_user.id).first
    follow.destroy if follow
  end

  def load_task_by_id
    @task = ::Task.accessible_by(current_ability).where(id: params[:id]).first
    unless @task
      render(json: ::DanthesService.new(Task.new).json_for_push_to_browser.to_json, status: :method_not_allowed)
      return false
    end
    @task_service = ::TaskService.new(@task, params)
  end

  def change_state
    event = params[:event] if @task.aasm.events.map{|e| e.name.to_s}.include?(params[:event])
    @task.__send__(event)
    @task.assigned_to_user_id = @task.state.eql?('new') ? nil : current_user.id
    @task.result              = params[:result] if params[:result]

  end

  def update_settings
    if params[:service_channel_id]
      service_channel = current_user.service_channels.where(id: params[:service_channel_id]).first
      service_channel = current_user.service_channel if current_user.service_channel and current_user.service_channel.id == params[:service_channel_id].to_i
      @task.service_channel_id = service_channel.nil? ? nil : service_channel.id
      @task.media_channel_id = service_channel.__send__(MediaChannel::get_channel_type_by_classname(@task.media_channel.type) + '_media_channel').id
    end

    if params[:agent_id].blank?
      agent = nil
    else
      agent = @task.service_channel.users.where(id: params[:agent_id]).first
    end
    @task.assigned_to_user_id = agent.nil? ? nil : agent.id

    if (params[:agent_id].blank? or params[:agent_id] != current_user.id.to_s) and @task.state != "new"
      @task.renew
    end

    @task.skill_list = ""
    @task.generic_tag_list = ""
    unless params[:tags].blank?
      company_skill_list = current_user.company.skill_list
      params[:tags].split(',').map(&:strip).uniq.each do |tag|
        if company_skill_list.include?(tag)
          @task.skill_list.add(tag)
        else
          @task.generic_tag_list.add(tag)
        end
      end
    end
    if params[:is_urgent] == "true"
      @task.flag_list.add("urgent")
    else
      @task.flag_list.remove("urgent")
    end
  end

  def current_user_ready_tasks (offset)

    @current_user_ready_tasks = ::Task.accessible_by(current_ability).
      eager_load(:agent,
                 :service_channel,
                 :media_channel,
                 messages: [:task, :attachments],
                 service_channel: [{locations: [weekly_schedule: [:schedule_entries]]}, weekly_schedule: :schedule_entries],
                 media_channel: [weekly_schedule: :schedule_entries]
      ).preload(:note)
      .where(state: :ready)
      .order('tasks.created_at DESC').limit(30).offset(offset)
  end

  def task_params
    @task_params ||= params.permit(
        :media_channel_id,
        :service_channel_id,
        :assigned_to_user_id,
        :email_to_addresses,
        :email_subject,
        :email_message,
        :email_lang,
        :skills,
        :flags,
        :is_from_chatbot_custom_action_button,
        messages_attributes: messages_attributes
    )
  end

  def messages_attributes
    @messages_attributes ||= [
        :description,
        :title,
        :channel_type,
        :from,
        :to,
        :is_internal,
#        attachments: []
    ]
  end
end
