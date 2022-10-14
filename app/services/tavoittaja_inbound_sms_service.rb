class TavoittajaInboundSmsService
  include Interactor

  def call
    set_full_e164_phone_numbers
    find_last_message_to_sender
    add_sms_to_task
  rescue StandardError => error
    Rails.logger.error error.message
    context.fail!(message: error.message)
  end

  private

  def set_full_e164_phone_numbers
    context.sender_full_e164 = Phonelib.parse(context.sms_params[:sender]).full_e164
    context.recipient_full_e164 = Phonelib.parse(context.sms_params[:recipient]).full_e164
  end

  def find_last_message_to_sender
    if last_message_to_sender = Message.where('(messages.to LIKE :number AND messages.sms = true) OR (messages.from LIKE :number AND messages.sms != true)', number: context.sender_full_e164).order(created_at: :desc).first
      context.last_message_to_sender = last_message_to_sender
    else
      context.fail!(message: "tavoittaja_inbound_sms_service.last_message_to_sender_not_found")
    end
  end

  def add_sms_to_task
    task = Task.unscoped.find context.last_message_to_sender.task_id
    task.data_will_change!
    task.data['missing_sms_counter'] = if task.data['missing_sms_counter']
      task.data['missing_sms_counter'] + 1
    else
      1
    end
    ActiveRecord::Base.transaction do
      context.created_sms = task.messages.create!(
        from: context.sender_full_e164,
        to: context.recipient_full_e164,
        description: context.sms_params[:message],
        number: task.messages.count + 1,
        channel_type: context.last_message_to_sender.channel_type,
        sms: true,
        in_reply_to_id: context.last_message_to_sender.id,
        need_push_to_browser: true,
        inbound: true
      )
      task.send_by_user = nil
      task.state = 'open' if task.state == 'ready'
      task.hidden = nil
      task.save!
    end

    if task.service_channel
      ::Fonnecta::Contacts.new(task.company, context.sender_full_e164).search
      company = task.company
      ::Company::Stat.update_counters company.current_stat.id, sms_received: 1
    end
  end
end
