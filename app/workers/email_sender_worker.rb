class EmailSenderWorker
  include ::Sidekiq::Worker
  def perform(message_id)
    message = ::Message.find(message_id)
    ::SmtpService.new(message).send_email
  end
end