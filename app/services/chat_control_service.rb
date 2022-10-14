class ChatControlService

  def initialize(media_channel_id, message)
    @message = message
    @channel_id = media_channel_id
  end

  def push_to_browser
  	puts "Chat Control Message......... : #{@message.inspect}"
    Danthes.publish_to "/chat/#{@channel_id}/control", @message
  end

end
