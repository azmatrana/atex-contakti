class TaskService

  attr_reader :task, :params

  def initialize(task, params = nil)
    @task, @params = task, params
  end

  def reply_from(user)
    reply      = ::MessageService.new(nil, params).reply_for(task)
    reply.user = user
    reply.from = user.full_name if reply.sms? || reply.from.blank?
    reply.from ||= user.email
    reply.need_send_email = true if need_send_email?(reply)
    reply.need_send_sms = true if reply.sms?
    puts "===========#{reply.inspect}=====#{reply.channel_type}====="
    if reply.save
      { ok: true, data: reply }
    else
      { ok: false, errors: reply.errors }
    end
  end

  def build_message_and_send_reply
    reply      = ::MessageService.new(nil, params).build_reply_for(task)
    reply.need_send_email = true if need_send_email?(reply)
    reply.need_send_sms = true if reply.sms?
    puts "=build_message_and_send_reply==========#{reply.inspect}=====#{reply.channel_type}====="
    ::SmtpService.new(reply).send_email
  end

  def change_state

  end

  def need_send_email?(reply)
    !!(%w[email chat internal web_form].include?(reply.channel_type) && !reply.sms?)
  end
end
