module TasksHelper

  def assigned_to_user?(task)
    task.assigned_to_user_id == current_user.id
  end

  def agents_collection
    ::User.with_role(:agent).for_company(current_user.company_id).map{|u| [u.full_name, u.id]}
  end

  def company_agents_collection
    User.with_role(:agent).for_company(current_user.company_id)
  end

  def service_channels_collection
    current_user.service_channels.map{|sc| [sc.name, sc.id]}
  end

  def company_service_channels_collection
    current_user.company_service_channels.reject do |channel|
      channel.agent_private?
    end
  end

  def state_collection
    ['new', 'open', 'waiting', 'ready'].map do |x|
      [I18n.t("activerecord.models.task.states.#{x}"), x]
    end
  end

  def media_channels_collection
    #    media_channels = %w{Email WebForm Call Sip Internal}.map{|i|
    media_channels = %w{Email WebForm Call Internal Sms}.map{|i|
      [t("users.agents.media_channel_types.#{i.underscore}"), 'MediaChannel::'+i]
    }

    #    preference_media_channels = {'chat' => "Chat", 'facebook' => "Facebook"}
    preference_media_channels = {'chat' => "Chat"}

    preference_media_channels.each do |key, value|
      if current_user.company.__send__("prefers_having_" + key + "?")
        media_channels << [t("users.agents.media_channel_types.#{value.underscore}"), 'MediaChannel::'+value]
      end
    end

    media_channels
  end

  def media_channels_for_filter_collection
    media_channels_collection.map{|arr|
      [arr.first, arr.last.split('::').last.underscore]
    }
  end

  def skill_collection
    current_user.company.skill_list.map{|s| [s, s]}
  end

  def flags_collection
    [
      ['urgent', 'urgent']
    ]
  end

  def wit_api_settings
    settings = {
      protocol: ENV["WIT_API_PROTOCOL"] || "http://",
      host: ENV["WIT_API_HOST"],
      port: ENV["WIT_API_PORT"],
      client_id: ENV["WIT_API_CLIENT_ID"],
      wit_token: ENV["WIT_API_TOKEN"]
    }
    return settings
  end

  def post_to_wit_api(task)
    wit_token = task.company.wit_token
    unless wit_token.present?
      return
    end
    logger.info("Wit request for task #{task.inspect}")
    require 'net/http'
    require 'json'
    settings = wit_api_settings
    begin
      endpoint = '/api/messages'
      uri = URI(settings[:protocol] + settings[:host] + endpoint)
      http = Net::HTTP.new(uri.host, settings[:port])
      req = Net::HTTP::Post.new(uri.path, {
        'Content-Type' =>'application/json',
      #'Authorization' => 'XXX'
      })

      client_id = task.company_id.present? ? task.company_id : settings[:client_id]
      # wit_token = settings[:wit_token] if wit_token.blank?

      task.messages.each do |task_message|
        next unless task_message.id? && task_message.description?
        description = task_message.from.to_s + '<br/>' + task_message.to.to_s + '<br/>' + task_message.title.to_s + '<br/>' + task_message.description + '<br/>' + task_message.call_transcript.to_s
        req.body = {
          message: {
            clientId: client_id,
            messageId: task_message.id,
            text: description,
            wit_token: wit_token
          }
        }.to_json
        logger.info("Wit request body #{req.body.inspect}")
        res = http.request(req)
        logger.info("Wit response OK #{res.body}")
        map_wit_tags_to_task_tags(JSON.parse(res.body), task)
      end
      return true
    rescue => e
      logger.error("Wit request failed #{e}")
      return false
    end
  end

  def map_wit_tags_to_task_tags(wit_response, task)
    logger.info("Wit response map tags #{wit_response.class} #{wit_response.inspect}")
    if wit_response && wit_response["tags"]
      wit_response["tags"]["tags"].each do |tag|
        task.generic_tag_list.add(tag) unless task.generic_tag_list.include?(tag)
      end
    end
    return task
  end
end
