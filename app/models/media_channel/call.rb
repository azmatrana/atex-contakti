# == Schema Information
#
# Table name: media_channels
#
#  id                 :integer          not null, primary key
#  service_channel_id :integer
#  type               :string(50)       default(""), not null
#  imap_settings_id   :integer
#  smtp_settings_id   :integer
#  created_at         :datetime
#  updated_at         :datetime
#  group_id           :string(255)      default(""), not null
#  deleted_at         :datetime
#  autoreply_text     :text
#  active             :boolean          default(TRUE), not null
#  broken             :boolean          default(FALSE), not null
#  name_check         :boolean          default(FALSE), not null
#  send_autoreply     :boolean          default(TRUE), not null
#  yellow_alert_hours :decimal(4, 2)
#  yellow_alert_days  :integer
#  red_alert_hours    :decimal(4, 2)
#  red_alert_days     :integer
#  chat_settings_id   :integer
#
# Indexes
#
#  index_media_channels_on_deleted_at  (deleted_at)
#

class MediaChannel::Call < MediaChannel

  before_save :nullify_sms_sender
  before_save :check_group_id

  def channel_type
    'call'
  end

  def add_task(mail, email_text, msg_uid)
    caller_number = email_text.match(self.class.caller_id_regex).to_s
    extension = email_text.match(self.class.extension_regex).to_s
    self.add_task_from_hash({
      from: caller_number,
      to: extension,
      message_uid: msg_uid,
      description: mail.subject,
      group_id: email_text.match(self.class.call_group_id_regex)[:call_group_id]
    })
  end

  def add_task_from_json_message(hash)
    variables = hash["variables"]
    add_task_from_hash({ description: variables['datetime'],
                         from: variables['q_number'].blank? ? variables['callerid'] : variables['q_number'],
                         to: variables['extension'],
                         group_id: variables['extension'],
                         reply_to: variables['callerid'] })
  end

  def add_task_from_hash(data, send_call_sms=true)
    logger.info "Adding task from hash: #{data.inspect}"

    caller_number_phone_lib = ::Phonelib.parse data[:from]
    if caller_number_phone_lib.invalid?
      logger.info "Wrong caller number detected, will not create the task. Parsed data: #{data.inspect}"
      return
    end
    caller_number = caller_number_phone_lib.full_e164
    sms_reply_number = data[:reply_to].blank? ? caller_number : data[:reply_to]

    if data[:reply_to]
      data.delete(:reply_to)
    end

    ::Company::Stat.increment_counter :call_tasks_received, company.current_stat.id

    call_group_id = data.delete(:group_id)
    existing_task = ::Task.call_channel.joins(:messages).where(
                            media_channels: {
                              group_id: call_group_id,
                              id: self.id,
                              deleted_at: nil
                            },
                            messages: {
                              from: [caller_number, data[:from]]
                            },
                            state: :new
                          ).first
    if existing_task
      task = existing_task
    else
      task_attributes = {
        media_channel_id: self.id,
        service_channel_id: self.service_channel_id
      }

      task = ::Task.new(task_attributes)
    end

    message_title = "Unanswered call #{caller_number}"
    message_title = "Callback request #{caller_number}" if send_call_sms == false

    message = task.messages.build data.merge({
      from: caller_number,
      title: "#{message_title}",
      description: data[:description] || data[:created_at],
      number: task.messages.count + 1,
      channel_type: 'call',
      need_push_to_browser: true
    })
    Rails.logger.info "Message before saving: #{message.inspect}"
    task.data_will_change!
    task.data['missing_calls_counter'] = if task.data['missing_calls_counter']
                                          task.data['missing_calls_counter'] + 1
                                         else
                                           1
                                         end
    if !task.customer_id
      task.customer_id = Customer.where(
        contact_phone: caller_number,
        company_id: service_channel.company_id
      ).select(:id).first.try(:id)
    end
    if self.name_check?
      ::Company::Stat.increment_counter :call_task_name_checks, company.current_stat.id
      begin
        task.data['caller_name'] = ::Fonnecta::Contacts.new(self.company, caller_number).search
      rescue Exception => e
        logger.warn "Fonnecta name check failed with #{e.message}"
        task.data['caller_name'] = I18n.t('tasks.default_from')
      end
    end
    task.save!
    if self.send_autoreply? && self.autoreply_text.present? && send_call_sms == true
      ::Company::Stat.increment_counter :call_task_autoreplies, company.current_stat.id
      reply_text = self.autoreply_text.gsub(MediaChannel::Call.auto_reply_callerid_regex, data[:from])
      ::SmsSenderWorker.perform_async(
        self.sms_sender, sms_reply_number, reply_text, self.service_channel.company_id
      )
    end
  end

  def check_group_id
    return true if self.active == false && active_changed?
    return true if self.active == false && !group_id_changed?
    self.active = self.group_id.present?
    self.broken = !self.active
    true
  end

  def settings_present?
    self.group_id.present?
  end


  def run_test_check; end

  def set_unbroken
    true
  end

  private

  def nullify_sms_sender
    self.sms_sender = nil if sms_sender.blank?
  end

  class << self
    def parse_call_detail_xml(doc)
      doc.xpath('//calldata').map do |el|
        {
          description:  el.xpath('calltime').inner_text,
          from:         el.xpath('callerid').inner_text,
          to:           el.xpath('extension').inner_text,
          group_id:     el.xpath('destination').inner_text
        }
      end
    end

    def call_group_id_regex
      /Service Channel (?<call_group_id>\w+),/
    end

    def caller_id_regex
      /(?<=Callerid: )[\w+]+/
    end

    def extension_regex
      /(?<=Extension: )[\w+]+/
    end

    def auto_reply_callerid_regex
      /\$\(caller_id\)/
    end

    def delayed_add_task_from_hash(id, data, send_call_sms=true)
      media_channel = MediaChannel::Call.find(id)
      media_channel.add_task_from_hash(data, send_call_sms)
    end
  end
end
