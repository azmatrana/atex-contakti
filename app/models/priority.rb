class Priority < ActiveRecord::Base
  before_validation :prepare_expire_time
  acts_as_paranoid

  def self.find_priority(company, skill_id)
    priorities_hash = Rails.cache.fetch("priority_#{company}_cache_key") do
      Priority.where(company_id: company).pluck(:tag_id, :priority_value).to_h
    end
    priorities_hash[skill_id] || 0
  end

  def self.find_priority_with_skill_id(company, skill_id)
    priorities_hash = Rails.cache.fetch("priority_#{company}+#{skill_id}_cache_key") do
      Priority.where(company_id: company, tag_id: skill_id).pluck(:tag_id, :priority_value).to_h
    end
    priorities_hash || {}
  end

  def alarm_emails
    email_receivers = []

    alarm_receivers.to_s.split(',').each do |receiver|
      receiver.strip
      email_receivers << receiver if receiver.match(URI::MailTo::EMAIL_REGEXP).present?
    end

    email_receivers
  end

  def alarm_sms_numbers
    (alarm_receivers.to_s.split(',').collect(&:strip) - alarm_emails)
  end

  def trigger_alarm(tag_name, task_id)
    task = Task.where(id: task_id).last
    return if task.blank?

    trigger_email_alarm(tag_name, task)
    trigger_sms_alarm(tag_name, task)
  end

  def trigger_email_alarm(tag_name, task)
    email_messsage = email_template
    return if email_messsage.blank?

    alarm_emails.each do |email|
      ::AlarmMailer.send_priority_alarm(email, email_messsage, "Priority alarm for #{tag_name}").deliver
    end
  end

  def trigger_sms_alarm(tag_name, task)
    sms_messsage = sms_template
    return if sms_messsage.blank?

    service_channel = task.service_channel
    from = service_channel.sms_media_channel.try :sms_sender

    alarm_sms_numbers.each do |phone_number|
      ::SmsSenderWorker.perform_async(
        from, phone_number, sms_messsage, self.company_id
      )
    end
  end

  def prepare_expire_time
    if expire_time.blank?
      self.expire_time = 0
    end
  end
end
