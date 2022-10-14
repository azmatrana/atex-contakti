class ChatHistoryMailer < ActionMailer::Base
  default from: 'support@contakti.com'

  def chat_history(email, message, title, options = {})
    # create a screenshot
    @email = email
    @message = message

    mail to: @email, subject: "#{title}"
  end
end
