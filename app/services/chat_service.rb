class ChatService

  def self.push_to_browser(message)
  	puts "Message......... : #{message.inspect}"
    Danthes.publish_to message['channel_id'], message
  end

end

