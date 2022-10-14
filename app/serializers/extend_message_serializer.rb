class ExtendMessageSerializer < ActiveModel::Serializer
  attributes :id,
             :channel_type,
             :created_at,
             :from,
             :from_email,
             :is_internal,
             :number,
             :sms,
             :in_reply_to_id,
             :task_id,
             :title,
             :to,
             :user_id,
             :description,
             :formatted_description,
             :attachments,
             :service_channel_name,
             :inbound,
             :cc,
             :bcc,
             :call_transcript,
             :marked_as_read


  %i[cc bcc].each do |f|
    define_method f do
      val = object.send(f)

      return if val.blank?

      val.respond_to?(:join) ? val.join(', ') : val.to_s
    end
  end

  def in_reply_to_id
    object[:in_reply_to_id]
  end

  def service_channel_name
    object.task.try(:service_channel).try(:name)
  end

  def attachments
    object.attachments.map do |attachment|
      Message::AttachmentSerializer.new(attachment, root: false)
    end
  end
end
