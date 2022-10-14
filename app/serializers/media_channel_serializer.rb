class MediaChannelSerializer < ActiveModel::Serializer
  attributes *MediaChannel.attribute_names.map(&:to_sym), :type, :chat_control_channel, :chat_settings

  def chat_control_channel
    if(object.respond_to?(:control_channel))
     object.control_channel
   else
     nil
   end
  end

  def chat_settings
    if object.respond_to?(:chat_settings)
      object.chat_settings
    else
      nil
    end
  end
end
