class WitService

  def initialize(company)
    if company.present? && company.have_chatbot?
      @access_token = company.wit_chatbot_token
      @client = Wit.new(access_token: @access_token)
    end
  end

  def send_message_to_wit(message = '')
    return unless @access_token
    @client.message(message)
  end

  def send_intent_to_wit(intent)
    return unless @access_token
    intent_payload = { name: intent}
    @client.post_intents(intent_payload)
  end

  def send_utterance_to_wit(hash)
    return unless @access_token
    utterance_payload = set_utterance_payload(hash)
    resp = @client.post_utterances(utterance_payload)
  end

  def delete_utterances_from_wit(hash)
    return unless @access_token
    resp = @client.delete_utterances(hash)
    puts "---------------- ---"
    puts resp
    return resp["sent"]
  end

  def delete_intents_from_wit(intent)
    return unless @access_token
    resp = @client.delete_intents(intent)
    puts "---------------- ---"
    puts resp
    return resp["sent"]
  end

  def delete_entities_from_wit(entity)
    return unless @access_token
    resp = @client.delete_entities(entity)
    return resp["sent"]
  end

  def set_utterance_payload(obj)
    utterance_payload = {
      text: obj[:question],
      intent: obj[:intent],
      entities: obj[:entities],
      traits: obj[:traits]
    }

  end

  def create_entity_at_wit(entity_obj)
    return unless @access_token
    payload = {:name => entity_obj[:name],
               :roles =>[]}
    resp = @client.post_entities(payload)
  end

  def send_entity_to_wit(entity_obj)
    return unless @access_token
    payload = {:name => entity_obj[:name],
               :roles => [entity_obj[:name]],
               :lookups => ["free-text", "keywords"],
               :keywords => entity_obj[:key_words] }
    resp = @client.put_entities(entity_obj[:name],payload)
  end

  def get_keys_from_message(wit_response)
    # json_response = JSON.parse(wit_response)
    intents = []
    if wit_response["intents"].present?
      intents_data = wit_response["intents"]
      intents_data.each do |intent|
        intents.push(intent['name'])
      end
    end
    entities = {}
    if wit_response["entities"].present?
      keys_data = wit_response["entities"]
      wit_response["entities"].keys.each do |entity_key|
        keys_data[entity_key].each do |entiy_data|
          entitiy_name = entiy_data["name"]
          entitiy_value = entiy_data["value"]
          entities[entitiy_name] = entitiy_value
        end
      end
    end

    return { :intents => intents, :entities => entities }
  end


  def get_intent_from_wit_response(wit_response)
    intent_text = nil
    if wit_response["intents"].present? && wit_response["intents"].length > 0
      confidence = 0.6
      intent_text = ''
      wit_response["intents"].each do | intent|
        if intent["confidence"] > confidence
          intent_text = intent["name"]
        end
      end
    end

    return intent_text
  end
end
