class ChatController < ApplicationController
#  before_action  lambda{|c| c.check_current_users_company_preference("chat", nil) if current_user}
#  before_action  :check_if_chat_allowed
  #before_action :referer_check, only: [:show, :join]
  layout false


  skip_before_action :verify_authenticity_token, only: [:show, :build_plugin]
  skip_before_filter :verify_authenticity_token, :authenticate_user!, :update_current_session

  # Render the stuff needed by client browser
  def show
      # response.headers.delete('X-Frame-Options')

      @id = params[:id]
      @media_channel = MediaChannel::Chat.find(params[:id])
      # @chat_available = false
      @settings = @media_channel.chat_settings
      @chat_available = @media_channel.agents_online? || @settings.enable_chatbot
  end

  def build_plugin
    response.headers.delete('X-Frame-Options')
    render file: "public/contakti-chat-plugin/index.html"
  end

  def relay_control_message
    @id = params[:id]
    message = {:type => params[:type], :client_channel => params[:channel_id], :message => params[:message]}
    message[:client_info] = params[:client_info] if params[:client_info]
    message[:recipient] = params[:recipient] if params[:recipient]
    message[:service_channel_id] = params[:service_channel_id] if params[:service_channel_id]
    message[:from] = params[:from] if params[:from]

    ChatControlService.new(params[:id], message).push_to_browser
    render json: {ok: true}
  end

  def send_msg
    logger.info "send msg params......... : #{params.inspect}"
    msg_params = check_params
    msg_params[:channel_id] = '/chat/' + msg_params[:id]
    puts "#{msg_params}"

    if msg_params[:type] == 'quit'
      record = ChatRecord.where(channel_id: msg_params[:channel_id]).first
      if !record.user_quit
        record.ended_at = DateTime.now
        record.save
      end
    end

    message = ChatMessage.new(msg_params)
    logger.info "send_message Message......... : #{message.inspect}"
    if msg_params[:id].length == 33 && !msg_params[:id].index("_").nil? #This is probably a facebook id. Todo: Check it some other way...
      FacebookPushWorker.perform_async(msg_params[:id],message)
    else
      redis = Redis.new
      logger.info "start redis......... : #{redis.inspect}"
      redis.rpush(msg_params[:id], message.to_json)
      redis.expire(msg_params[:id], 7200)
      logger.info "end redis......... : #{redis.inspect}"
      ChatPushWorker.perform_async(message)
    end
    render json: {ok: true}
  end


  def send_indicator
    msg_params = check_params
    msg_params[:channel_id] = '/chat/' + msg_params[:id]
    puts "#{msg_params}"

    if msg_params[:type] == 'quit'
      record = ChatRecord.where(channel_id: msg_params[:channel_id]).first
      if !record.user_quit
        record.ended_at = DateTime.now
        record.save
      end
    end

    msg_params[:type] = 'agent_indicator' if msg_params[:type] == 'message'
    message = ChatMessage.new(msg_params)
    if msg_params[:id].length == 33 && !msg_params[:id].index("_").nil? #This is probably a facebook id. Todo: Check it some other way...
      FacebookPushWorker.perform_async(msg_params[:id],message)
    else
      redis = Redis.new
      redis.rpush(msg_params[:id], message.to_json)
      redis.expire(msg_params[:id], 7200)
      ChatPushWorker.perform_async(message)
    end
    render json: {ok: true}
  end

  def log
    redis = Redis.new
    messages = redis.lrange(params[:id], 0, -1)
    messages.collect! { |m| JSON.parse m }
    render json: messages.to_json
  end

  def subscribe_to_control
    @id = params[:id]
    channel = "/chat/#{@id}/control"
    render :json => Danthes.subscription(channel: channel)
  end

  def join
    @id = params[:id]
    channel = "/chat/#{@id}"
    record = ChatRecord.where(channel_id: channel).first
    if record.answered_at.nil?
      record.answered_at = DateTime.now
      record.answered_by_user_id = current_user.id
      record.save
    end

    render :json => Danthes.subscription(channel: channel)
  end

  def rate
    @id = params[:id]
    channel = "/chat/#{@id}"
    record = ChatRecord.where(channel_id: channel).first
    record.result = params[:result]
    record.save

    render :json => {}, :status => 200
  end

  def get_vehicle_data
    payload = {registration_number: params[:reg_num], access_token: current_user.company.spare_parts_api_key}
    data_fetcher = VehicleData.new(payload)
    res = data_fetcher.fetch_vehicle_info
    render json: res
  end

private
  def referer_check
    if request.referer
      referer =  URI(request.referer).host
      whitelist = @m.chat_settings.whitelisted_referers
      whitelist.split(',').map(&:strip).include?(referer.gsub(/\Awww./, '')) if whitelist.present?
    end
  end

  def check_params
    params.permit(:id, :type, :message, :from, :channel_id, :file_path)
  end

  def check_if_chat_allowed
    if !current_user
      unless (@m = MediaChannel::Chat.find(params[:id])) && @m.company.preferes_having_chat?
        render :json => {:error => "Not allowed"}, :status => :forbidden
      end
      end
  end
end
