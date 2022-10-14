class MediaChannel::Sms < MediaChannel
  def channel_type
    'sms'
  end

  def settings_present?
    true
  end

  def add_hidden_task(from, to, text)
    task_attrs = {
      service_channel_id: self.service_channel_id,
      hidden: true,
      data: {},
      group_sms: true
    }
    begin
      task_attrs[:data]['caller_name'] = ::Fonnecta::Contacts.new(self.company, to).search
    rescue Exception => e
      logger.warn "Fonnecta name check failed with #{e.message}"
      task_attrs.data['caller_name'] = I18n.t('tasks.default_from')
    end
    message_attrs = {
      from: from,
      to: to,
      description: text,
      sms: true,
      channel_type: 'sms'
    }
    task = self.tasks.build task_attrs
    task.messages.build message_attrs
    task.save!
  end

  def add_sms_task(from, to, text)
    task_attrs = {
      service_channel_id: self.service_channel_id,
      hidden: nil,
      data: {}
    }
    begin
      task_attrs[:data]['caller_name'] = ::Fonnecta::Contacts.new(self.company, to).search
    rescue Exception => e
      logger.warn "Fonnecta name check failed with #{e.message}"
      task_attrs.data['caller_name'] = I18n.t('tasks.default_from')
    end
    message_attrs = {
      from: from,
      to: to,
      description: text,
      sms: true,
      channel_type: 'sms'
    }
    task = self.tasks.build task_attrs
    task.messages.build message_attrs
    return task
  end
end
