class SendChatHistoryWorker
  include Sidekiq::Worker

  def perform(email,message,title)
    ::ChatHistoryMailer.chat_history(email,message,title).deliver
  end

end
