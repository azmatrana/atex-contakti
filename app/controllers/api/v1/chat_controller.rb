require 'fileutils'

class Api::V1::ChatController < Api::V1::BaseController

  include TasksHelper
  include BotMessageHelper
  # Initiates the chat. :id is mediaChannelId
  def initiate_chat
    channel_id = "/chat/#{SecureRandom.uuid}"

    # Send message to mediaChannel's control channel.
    logger.info "params initiate chat......... #{params.inspect}"
    message = {:type => 'incoming', :client_channel => channel_id, :message => '',
               client_info: {name: params[:name]}, chat_display_fields: params[:chat_display_fields], is_ad_finland_company: params[:is_ad_finland_company] }

    unless params[:chatbot] == "true" || params[:chatbot] == true
      logger.info "initiate chat message......... #{message.inspect}"
      ChatControlService.new(params[:id], message).push_to_browser
    end

    mc = MediaChannel.find(params[:id])
    ChatRecord.create(service_channel_id: mc.service_channel_id, media_channel_id: params[:id], channel_id: channel_id, name: params[:name], email: params[:email], phone: params[:phone])

    # Send subscription back to client
    render json: ::Danthes.subscription(channel: channel_id)
  end

  def get_chat_settings
    @media_channel = MediaChannel::Chat.find(params[:id])
    @company = @media_channel.company
    @shipment_methods = @company.shipment_methods
    @settings = @media_channel.chat_settings
    @inquiry_fields = @settings.chat_inquiry_fields.where.not("title IN ('', 'nil')" )
    @initial_buttons =  @settings.chat_initial_buttons.where.not("title IN ('', 'nil')" )
    @order_terms_and_conditions = @company.cart_email_templates.find_by(template_for: "terms_and_conditions")
    render json:{
        settings: @settings,
        chat_inquiry_fields: @inquiry_fields,
        chat_initial_buttons: @initial_buttons,
        agents_online: @media_channel.agents_online?,
        is_ad_finland_company: @company.is_ad_finland_company?,
        shipment_methods: @shipment_methods,
        currency: @company.currency,
        order_terms_and_conditions: @order_terms_and_conditions
    }
  end

  def get_translations
    # translations = I18n.backend.send(:translations)[( (I18n.locale || :en) rescue :en)]
    I18n.locale = nil
    translations = I18n.t(".")

    # puts translations
    render json: translations
  end

  def set_client_info
    redis = Redis.new
    logger.info "======SET CLIENT INFO PARAMS: #{params}======"
    client_id = redis.smembers("/danthes/channels#{params[:channel_id]}")[0]
    if client_id.present?
      client_data_key = "#{params[:channel_id]}_client_info"
      redis.set(client_data_key, client_id)
      redis.expire(client_data_key, 86400)
      redis_key = "client_#{client_id}_has_connection"
      redis.set(redis_key, 'false')
      redis.expire(redis_key, 86400)
      render json: {ok: true}
    else
      render json: {ok: false}
    end
  end

  def set_client_connected
    redis = Redis.new
    client_id = redis.get("#{params[:channel_id]}_client_info")
    redis_key = "client_#{client_id}_has_connection"
    redis.set(redis_key, 'true')
    redis.expire(redis_key, 86400)
    respond_to do |format|
      format.json {
        render json: {ok: true}
      }
    end
  end

  def has_client_left
    redis = Redis.new
    client_id = redis.get("#{params[:channel_id]}_client_info")
    redis_key = "client_#{client_id}_has_connection"
    key_exists = redis.exists(redis_key)
    client_has_connection = false
    client_has_connection = redis.get(redis_key) if key_exists == true
    if client_has_connection == 'true'
      render json: {left: false}
    else
      render json: {left: true}
    end
  end

  def send_quit
    msg = params.permit(:type, :from, :message, :channel_id)
    msg[:id] = params["channel_id"].split("/").pop
    record = ChatRecord.where(channel_id: params[:channel_id]).first
    record.user_quit = true
    now = DateTime.now
    if record.ended_at.nil? or now < record.ended_at
      record.ended_at = DateTime.now
    end
    record.save
    message = ChatMessage.new(msg)
    redis = Redis.new
    redis.rpush(msg[:id], message.to_json)
    redis.expire(msg[:id], 7200)
    ChatPushWorker.perform_async( message )
    respond_to do |format|
      format.json {
        render json: {ok: true}
      }
    end
  end

  def bot_initiate_human_chat
     message = {:type => 'incoming', :client_channel => params[:channel_id], :message => '',
               client_info: {name: params[:name]}, chat_display_fields: params[:chat_display_fields], is_ad_finland_company: params[:is_ad_finland_company] }
    # message = {:type => 'incoming', :client_channel => params[:channel_id], :message => '',
    #            client_info: {name: params[:name], email: params[:email], phone: params[:phone]}}
    logger.info "initiate chat message......... #{message.inspect}"
    ChatControlService.new(params[:id], message).push_to_browser
    @media_channel = MediaChannel::Chat.find(params["id"])
    @agent_online = @media_channel.agents_online?
    render json: {agent_online: @agent_online}, status: 200
  end

  def abort_chat
    channel_id = params[:channel_id]

    # Send message to mediaChannel's control channel.
    message = {:type => 'abort', :client_channel => channel_id, :message => ''}
    ChatControlService.new(params[:id], message).push_to_browser
    record = ChatRecord.where(channel_id: params[:channel_id]).first
    now = DateTime.now
    if record.ended_at.nil? or now < record.ended_at
      record.ended_at = DateTime.now
      record.save
    end
    # Send subscription back to client
    render json: {}, status: 200
  end


  # Send message to chat channel. :id should be channel_id
  # Do we need this? Or chat goes only through danthes?
  # Maybe through this so we can log each chat message as it comes.
  def send_msg
    msg_params = check_params
    channel_id = '/chat/' + msg_params[:id]
    msg_params[:channel_id] = channel_id
    if msg_params[:type] == 'quit'
      record = ChatRecord.where(channel_id: msg_params[:channel_id]).first
      record.user_quit = true
      now = DateTime.now
      if record.ended_at.nil? or now < record.ended_at
        record.ended_at = DateTime.now
      end
      record.save
    end

    message = ChatMessage.new(msg_params)
    redis = Redis.new
    redis.rpush(msg_params[:id], message.to_json)
    redis.expire(msg_params[:id], 7200)
    ChatPushWorker.perform_async( message )

    if params[:chatbot] == "true" || params[:chatbot] == true
      check_bot_for_reply(message, msg_params[:id])
    end
    render json: {ok: true}
  end

  def send_indicator
    msg_params = check_params
    msg_params[:channel_id] = '/chat/' + msg_params[:id]

    if msg_params[:type] == 'quit'
      record = ChatRecord.where(channel_id: msg_params[:channel_id]).first
      if !record.user_quit
        record.ended_at = DateTime.now
        record.save
      end
    end
    msg_params[:type] = 'indicator' if msg_params[:type] == 'message'
    message = ChatMessage.new(msg_params)
    redis = Redis.new
    redis.rpush(msg_params[:id],  message.to_json)
    redis.expire(msg_params[:id], 7200)
    ChatPushWorker.perform_async(msg_params)
    render json: {ok: true}
  end


  def create_callback
      @id = params[:id]
      chat_media_channel = MediaChannel::Chat.find(params[:id])
      service_channel = chat_media_channel.service_channel
      result = nil

      if params[:number].present? and params[:datetime].present?
        if ::Phonelib.parse(params[:number]).invalid?
          logger.error "Wrong number #{params[:number]}"
          result = false
        else
          date = Time.zone.parse(params[:datetime])
          media_channel = service_channel.call_media_channel

          MediaChannel::Call.delay_until(date).delayed_add_task_from_hash(media_channel.id, {
            from: params[:number],
            to: media_channel.group_id,
            group_id: media_channel.group_id,
            description: params[:datetime]
          }, false)

          if (date - Time.zone.now) > MediaChannel::Chat::CALLBACK_SMS_GAP.minutes
            MediaChannel::Chat.delay_until(date - MediaChannel::Chat::CALLBACK_SMS_GAP.minutes).delayed_auto_sending_sms_from_chat(chat_media_channel.id, {
              from: service_channel.sms_media_channel.sms_sender,
              to: params[:number],
              text: service_channel.chat_media_channel.try(:autoreply_text),
              company_id: service_channel.company_id
            }) if service_channel.company.sms_provider && service_channel.sms_media_channel.sms_sender.present?
          end

          result = true
        end
      end
      if params[:email].present? and params[:message].present?
        media_channel = (service_channel.web_form_media_channel and service_channel.web_form_media_channel.active?) ? service_channel.web_form_media_channel : service_channel.email_media_channel
        customer_id = Customer.where(
          contact_email: params[:email].downcase,
          company_id: service_channel.company_id
        ).select(:id).first.try(:id)
        task = ::Task.new(
          media_channel_id: media_channel.id,
          service_channel_id: service_channel.id,
          customer_id: customer_id
        )
        message = task.messages.build(
          title:          I18n.t('user_dashboard.callback_message_title'),
          description:    params[:message],
          from:           params[:email],
          to:             media_channel.imap_settings.from_email,
          number:         task.messages.count + 1,
          is_internal:    false,
          channel_type:   media_channel.channel_type
        )
        if message.valid? && task.save
          message.add_signature_to_description
          message.need_push_to_browser = true
          message.save
          post_to_wit_api(task)
          task.save
          result = true
        else
          logger.error "Failed to save task: #{task.inspect} #{task.errors.messages} #{message.inspect} #{message.errors.messages}"
          result = false
        end
      end

      render json: {ok: result}
  end

  def send_email_chat_history
    @id = params[:id]
    logger.info("====Inside===send_chat_history=========#{params.inspect}=================")
    if params[:email].present? and params[:message].present?
      ::SendChatHistoryWorker.perform_async(params[:email], params[:message], I18n.t('user_dashboard.chat_history'))
    else
      logger.error "Something went wrong!"
    end
    render json: {ok: true}
  end

  def uploadfile
    file = params[:upload]
    secure_token = SecureRandom.hex(10)
    extension = File.extname(file.original_filename)
#    new_filename = "#{secure_token}#{extension}"

    directory = File.join("public/chatuploads", secure_token)
    FileUtils.mkdir directory
    path = File.join(directory, file.original_filename)
    FileUtils.cp file.tempfile.path, path
    FileUtils.chmod "g+rw", directory
    FileUtils.chmod "g+rw", path

    render json: {
      status: 'ok',
      file_url: "#{Settings.protocol}://#{Settings.hostname}/chatuploads/#{secure_token}/#{file.original_filename}",
      file_path: "#{secure_token}/#{file.original_filename}"
    }
  end

  private

  def check_params
    params.permit(:id, :type, :message, :from, :channel_id, :file_path, :attempts)
  end

end
