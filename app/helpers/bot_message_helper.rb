module BotMessageHelper

  def check_bot_for_reply(message, uuid)
    channel_id = '/chat/' + uuid
    media_channel = ChatRecord.find_by_channel_id(channel_id).media_channel
    service_channel = media_channel.service_channel
    company = media_channel.company rescue nil
    bot_alias = media_channel.chat_settings.bot_alias rescue ''
    cart_enabled = media_channel.chat_settings.enable_cart
    msg_hash = message.to_hash
    logger.info "=====BOT MESSAGE HELPER msg_hash: #{msg_hash}"
    wit_response = get_response_from_bot(msg_hash['message'], company)
    wit_service = WitService.new(company)
    msg_intent_text = wit_service.get_intent_from_wit_response(wit_response)
    # if wit does not recognize the intent of question/message we try to replace the synonyms in
    # question with original keywords so that wit may recognize it.
    if msg_intent_text.blank? && wit_response["entities"].present?
      replaced_message = replace_synonyms_into_message(msg_hash['message'], wit_response["entities"])
      wit_response = get_response_from_bot(replaced_message, company)
      msg_intent_text = wit_service.get_intent_from_wit_response(wit_response)
    end
    answer = nil
    answer_files = []
    if msg_intent_text.present?  && company.present?
      intent = company.intents.find_by_text(msg_intent_text)
      if intent.present? && intent.answer.present?
        answer = intent.answer
        answer_files = answer.company_files
      end
    end

    if answer.present? && answer_files.present?
      reply_files = set_answer_files(answer_files)
      bot_msg_hash = set_bot_answer_with_files(channel_id, answer, msg_hash, bot_alias, company, reply_files)
    else
      bot_msg_hash = set_bot_answer(channel_id, answer, msg_hash, bot_alias, company, cart_enabled )
    end

    chatbot_stat = Chatbot::Stat.find_or_initialize_by(chat_channel_id: uuid, company_id: company.id, service_channel_id: service_channel.id)
    chatbot_stat.dealing_time = Time.now - (chatbot_stat.created_at || Time.now)
    if bot_msg_hash[:type] == 'switch_to_human'
      chatbot_stat.update(switched_to_agent: true)
    elsif bot_msg_hash[:type] == 'message'
      chatbot_stat.answered_messages += 1
      chatbot_stat.save
    end


    bot_message = ChatMessage.new(bot_msg_hash)
    redis = Redis.new
    redis.rpush(uuid, bot_message.to_json)
    redis.expire(uuid, 7200)
    ChatPushWorker.perform_async(bot_message)
  end

  def replace_synonyms_into_message(msg='', entities)
    # Doing this to call the wit again with the replaced synonyms to the original keywords.
    # Because if originall message/question is out of scope and it has synonyms in it. We are then
    # sending it again to the wit by replacing synonyms with original keywords. Assuming wit may return its intent.
    message_text = msg.dup
    keywords_data = {}
    count = 1
    entities.each do |key, entity_array|
      entity_array.each do |entity_details|
        start_index = entity_details["start"]
        end_index = entity_details["end"]
        key = "_"*((end_index - start_index) - 1) + "#{count}"
        keyword_hash = {original_text: entity_details['body'],
                        new_text: entity_details["value"]
        }
        keywords_data[key] = keyword_hash
        message_text[start_index..(end_index - 1)] = key
        count += 1
      end
    end
    keywords_data.each do |key, value|
      message_text = message_text.gsub(key, value[:new_text])
    end
    return message_text
  end

  def get_response_from_bot(message, company)
    wit_service = WitService.new(company)
    res = wit_service.send_message_to_wit(message)
  end

  def set_bot_answer(channel_id, answer=nil, message, bot_name, company, cart_enabled)

    bot_message = {}
    bot_message[:channel_id] = channel_id
    bot_message[:from] = bot_name.present? ? bot_name: ""
    bot_message[:type] = "message"

    if answer.blank?
      bot_message[:type] = message["attempts"] == 1 ? "retry" : "switch_to_human"
      #  create entry in db
      message = message["message"].present? ? message["message"] : ''
      # Message contains \n and \t sometime or extra space
      message = message.squish
      already_question = company.questions.where('lower(text) = ?', message.downcase).first
      unless already_question
        company.question_templates.where('lower(text) = ?', message.downcase).first_or_create(text: message)
      end
    end

    if answer.present? && answer.products.present? && cart_enabled == false
      answer = nil
    end
    

    bot_message[:message] = answer.present? ? answer.text : 'Unable to recogonize message, please ask something I know :) '
    bot_message[:has_custom_action] = answer.present? ? answer.has_custom_action : false
    bot_message[:custom_action_text] = (answer.present? && answer.has_custom_action == true) ? answer.custom_action_text : ""
    bot_message = set_extra_data(answer, bot_message)
    bot_message
  end

  def set_bot_answer_with_files(channel_id, answer, message, bot_name, company, files)
    bot_message = {}
    bot_message[:channel_id] = channel_id
    bot_message[:from] = bot_name
    bot_message[:type] = "bot_message_with_file"
    bot_message[:message] = answer.text
    bot_message[:files] = files
    bot_message[:has_custom_action] = answer.present? ? answer.has_custom_action : false
    bot_message[:custom_action_text] = (answer.present? && answer.has_custom_action == true) ? answer.custom_action_text : ""
    bot_message = set_extra_data(answer, bot_message)
    bot_message
  end

  def set_extra_data(answer, bot_message)
    if answer.present?
      if answer.answer_buttons.present?
        bot_message[:action_buttons] = answer.answer_buttons
      end
      if answer.products.present?
        bot_message[:products] = answer.products.as_json(methods: [:actual_price, :tax_amount], include: [:images, :attachments, :vat])
      end
      if answer.images.present?
        bot_message[:images] = answer.images
      end
    end
    bot_message
  end

  def set_answer_files(files_array)
    files = []
    files_array.each do |f|
      file_object = {}
      file_object[:id] = f[:id]
      file_object[:url] = "#{Settings.protocol}://#{Settings.hostname}/#{f.file.url}"
      file_object[:size] = f[:file_size]
      file_object[:name] = f[:file_name]
      files << file_object
    end
    files
  end
end
