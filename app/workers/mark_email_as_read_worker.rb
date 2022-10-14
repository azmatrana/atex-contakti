class MarkEmailAsReadWorker
  include Sidekiq::Worker

  def perform(task_id)
    task = ::Task.find(task_id)
    media_channel = task.media_channel
    task.messages.each do |message|
      if message.message_uid.present? && message.marked_as_read != nil && message.marked_as_read == false
        ::ImapService.mark_as_read(media_channel, message.id)
      end
    end
  end
end