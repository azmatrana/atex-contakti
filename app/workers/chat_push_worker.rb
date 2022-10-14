class ChatPushWorker
  include ::Sidekiq::Worker
  sidekiq_options unique: true
  def perform(message)
    ChatService.push_to_browser(message)
    # keys = message_for_bot(message)

  end
end
