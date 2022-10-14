class AlarmMailer < ActionMailer::Base
  default from: 'support@contakti.com'

  def send_priority_alarm(email, message, subject)
    @email = email
    @message = message

    mail to: @email, subject: subject
  end
end
