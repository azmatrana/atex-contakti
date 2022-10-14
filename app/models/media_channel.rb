class MediaChannel < ActiveRecord::Base
  include TasksHelper

  acts_as_paranoid
  acts_as_taggable_on :skills
  before_validation :set_send_auto_reply_flag, on: [:create]
  belongs_to :service_channel
  belongs_to :imap_settings
  belongs_to :smtp_settings
  belongs_to :chat_settings
  belongs_to :sip_settings

  belongs_to :user # for agent media channel(private, only for sending messages from Agent)

  has_many :tasks

#  has_many :users, ->(media_channel) { where("? = ANY(media_channel_types)", ::MediaChannel.get_channel_type_by_classname(media_channel.type)) },
#           class_name: 'User',
#           through: :service_channel

  def set_send_auto_reply_flag
    if self.type == 'MediaChannel::Email'|| self.type == 'MediaChannel::WebForm'
      self.send_autoreply = false
    end
  end
  def users
    service_channel.users.where("? = ANY(media_channel_types)", ::MediaChannel.get_channel_type_by_classname(type))
  end

  delegate :company, to: :service_channel

  accepts_nested_attributes_for :imap_settings
  accepts_nested_attributes_for :smtp_settings
  accepts_nested_attributes_for :chat_settings, :allow_destroy => true
  accepts_nested_attributes_for :sip_settings

  include SlaAlertable
  include WeeklySchedulable

  scope :emails, -> { where(type: 'MediaChannel::Email') }
  scope :web_forms, -> { where(type: 'MediaChannel::WebForm') }
  scope :calls, -> { where(type: 'MediaChannel::Call') }
  scope :chat, -> { where(type: 'MediaChannel::Chat' ) }
  scope :internals, -> { where(type: 'MediaChannel::Internal') }
  scope :sms, -> { where(type: 'MediaChannel::Sms') }

  before_save :set_unbroken

  def company_id
    service_channel.try(:company_id)
  end

  def internal?
    self.is_a? ::MediaChannel::Internal
  end

  def web_form?
    self.is_a? ::MediaChannel::WebForm
  end

  def call?
    self.is_a? ::MediaChannel::Call
  end

  def sms?
    self.is_a? ::MediaChannel::Sms
  end

  def set_unbroken
    if Settings.channels.try(:always_active)
      self.active = true
      self.broken = false
      return
    end

    self.active = true if internal? || sms?
    return true if self.active == false && !changed?
    return true if self.active == false && ((imap_settings.nil? || smtp_settings.nil?) || (!imap_settings.changed? && !smtp_settings.changed?)) && !broken?
    self.active = self.settings_present?
    self.broken = false
    true
  end

  def settings_present?
    %i(imap_settings smtp_settings sip_settings).all? do |key|
      settings = __send__(key)
      settings && settings.all_required_data_fills?
    end
  end

  def channel_type
    'email' # default
  end

  def self.get_message_from(mail, email_text = nil)
    mail.from.first
  end

  def run_test_check
    ::MediaChannelWorker.perform_async(id)
  end

  def self.add_message(task, mail, email_text, msg_uid, reply_to_message, options = {})
    # Rails.logger.info "ADD MESSAGE METHOD"
    return if mail.to.nil?
    # Rails.logger.info "BEFORE BUILD"
    # email_text = email_text.force_encoding('iso8859-1').encode('utf-8')
    to_address = mail.to
    imap_email = task.service_channel.try(:email_media_channel).try(:imap_settings).try(:from_email)
    if to_address == "undisclosed-recipients:" || to_address == "Undisclosed recipients:" || to_address.blank? || to_address.empty?
      to_address = imap_email
    else
      to_address = mail.to.join(", ").present? ? mail.to.join(", ") : imap_email
    end

    message = task.messages.build(
      title:          mail.subject.present? ? mail.subject : "(no subject)" ,
      description:    email_text,
      from:           get_message_from(mail),
      to:             to_address,
      cc:             mail.cc,
      bcc:            mail.bcc,
      message_uid:    msg_uid,
      number:         task.messages.count + 1,
      in_reply_to_id: reply_to_message.try(:id),
      is_internal:    reply_to_message.try(:is_internal?) || false,
      channel_type:   options[:channel_type],
      marked_as_read: false

    )
    # Rails.logger.info "AFTER BUILD"
    mail.attachments.each do |attachment|
      # Rails.logger.info "MESSAGE ATTACHMENTS START"
      message.attachments.build(
        file_name:    attachment.filename,
        content_type: attachment.content_type,
        file: ::AttachmentStringIO.new(attachment.filename, attachment.body.decoded),
        file_size: attachment.body.decoded.bytesize
      )
      # Rails.logger.info "MESSAGE ATTACHMENTS AFTER BUILD"
    end

    begin
      # Rails.logger.info "SAVE MESSAGE"
      message.save!
      message.add_signature_to_description unless options[:no_signature]
      message.need_push_to_browser = true if options[:need_push_to_browser]
      message.need_send_email = true if options[:need_send_email]
      message.save!
      message.task.open! if message.task && message.task.agent && !task.open?
      message
    rescue
      # Rails.logger.error "Message errors: #{message.errors.full_messages} #{$!} : #{$!.message} - backtrace: #{$!.backtrace}"
      # Rails.logger.error 'Failed to save message!'
      # Rails.logger.error mail.to_yaml
      # Rails.logger.error message.to_yaml
      nil
    end
  end

  def add_sent_email_task(mail, email_text, options = {})
    ::ActiveRecord::Base.transaction do
      task_attributes = {
        media_channel_id: id,
        # service_channel.id using for creating service if it is not created yet(for agent private channel for ex.)
        service_channel_id: service_channel.id
      }
      # task_attributes[:state] = options[:task_state] if options[:task_state]
      task_attributes[:assigned_to_user_id] = options[:assigned_to_user_id] if options[:assigned_to_user_id]
      task_attributes[:use_assigned_user_email_settings] = options[:use_assigned_user_email_settings]

      to_address = mail.to.present? ? mail.to.first : service_channel.email_media_channel.imap_settings.from_email
      task_attributes[:customer_id] = Customer.where(
        contact_email: to_address.downcase,
        company_id: company_id
      ).select(:id).first.try(:id)

      task = ::Task.create(task_attributes)
      message = self.class.add_message(task, mail, email_text, nil, nil, channel_type: channel_type, need_send_email: true)
      if message == nil && task.persisted?
        task.destroy
      else
        wit_response = post_to_wit_api(task)
        task.save!
        if task.task_priority
          time = Priority.find_by(priority_value: task.task_priority, tag_id: task.skills.map(&:id), company_id: company_id).expire_time
          UpdateOpenTaskWorker.perform_in(time.minutes,task.id)
        else
          UpdateOpenTaskWorker.perform_in(0.minutes,task.id)
        end
      end
    end
  rescue ::ActiveRecord::StatementInvalid => e
    # puts "Error inserting record into database: #{e.message}\n#{e.backtrace.join("\n")}"
  end

  def add_fetched_email_task(mail, email_text, msg_uid, options = {})
    logger.info "---------------------------------------------------------------add_fetched_email_task----\n"*10
    ::ActiveRecord::Base.transaction do
      matching_email_text = email_text.gsub(/\r?\n> /, '')
      task_signature    = matching_email_text.match(::Message.task_signature_regex)
      message_signature = matching_email_text.match(::Message.message_signature_regex)
      reply_to_message  = nil
      task              = nil
      found             = false

      logger.info "------------------email_text, #{email_text}\n"
      logger.info "------------------task_signature, #{task_signature}\n"
      logger.info "------------------service_channel_id, #{service_channel_id}\n"
      logger.info "------------------matching_email_text, #{matching_email_text}\n"
      logger.info "------------------message_signature, #{message_signature}\n"
      # return if task_signature.nil?
      if task_signature
        logger.info "------------------TASK ALREADY EXIST"
        task = ::Task.where(
          uuid: task_signature[:task_id],
          service_channel_id: service_channel_id
        ).first
        logger.info "------------------TASK, #{task.inspect}\n"
        return unless task
        found = true
      else
        task_attributes = {
          media_channel_id: id,
          service_channel_id: service_channel_id
        }
        task_attributes[:customer_id] = Customer.where(
          contact_email: mail.from.first.downcase,
          company_id: service_channel.company_id
        ).select(:id).first.try(:id)

        logger.info "------------------CREATING NEW TASK, #{task_attributes}\n"
        task = ::Task.create(task_attributes)
        logger.info "------------------AFTER CREATING NEW TASK, #{task_attributes}\n"
      end

      return if task.messages.exists?(message_uid: msg_uid)

      reply_to_message = ::Message.where(id: message_signature[:message_id]).first if message_signature
      options = { channel_type: channel_type, need_push_to_browser: true }
      options[:no_signature] = true if task_signature
      logger.info "------------------CREATING NEW MESSAGE"
      message = self.class.add_message(task, mail, email_text, msg_uid, reply_to_message, options)
      logger.info "------------------AFTER NEW MESSAGE"
      if message.nil? && !found && task.persisted?
        logger.info "------------------DESTROY THE TASK"
        task.destroy
      else
        wit_response = post_to_wit_api(task)
        task.state = 'new' if task.state == 'ready'
        task.state = 'open' if task.state == 'waiting'
        task.save!
        if task.task_priority
          time = Priority.find_by(priority_value: task.task_priority, tag_id: task.skills.map(&:id), company_id: company_id).expire_time
          UpdateOpenTaskWorker.perform_in(time.minutes,task.id)
        else
          UpdateOpenTaskWorker.perform_in(0.minutes,task.id)
        end
      end

      if self.should_send_autoreply_email? && task.messages.count == 1
        logger.info "------------------CREATING AUTO REPLY"
        self.create_auto_reply_service(task)
      end
    end
  end

  def add_task(mail, email_text, msg_uid, options = {})
    # Added some glue here because of failed IMAP email fetches.
    # Added bool found and the if message == nil && found == false -stuff, as add_message won't throw anymore and returns nil if it fails.
    ::ActiveRecord::Base.transaction do
      matching_email_text = email_text.gsub(/\r?\n> /, '')
      task_signature    = matching_email_text.match(::Message.task_signature_regex)
      message_signature = matching_email_text.match(::Message.message_signature_regex)
      reply_to_message  = nil
      task              = nil
      found             = false
      if task_signature
        task = ::Task.where(
          uuid: task_signature[:task_id],
          media_channel_id: id,
          service_channel_id: service_channel_id
          ).first
        found = true
      end

      task_attributes = {
        media_channel_id: id,
        service_channel_id: service_channel_id
      }
      task_attributes[:state] = options[:task_state] if options[:task_state]
      task_attributes[:assigned_to_user_id] = options[:assigned_to_user_id] if options[:assigned_to_user_id]
      task_attributes[:use_assigned_user_email_settings] = options[:use_assigned_user_email_settings] if options[:use_assigned_user_email_settings]

      task ||= ::Task.new(task_attributes)
      reply_to_message = ::Message.where(id: message_signature[:message_id]).first if message_signature
      message = self.class.add_message(task, mail, email_text, msg_uid, reply_to_message, channel_type: channel_type, fetched_email: options[:fetched_email])
      if message == nil && found == false && task.persisted?
        task.destroy
      else
        task.save!
      end
    end
  rescue ::ActiveRecord::StatementInvalid => e
    # puts "Error inserting record into database: #{e.message}\n#{e.backtrace.join("\n")}"
  end

  def agents_online?
    users.where('is_online IS TRUE').count > 0
  end

  def should_send_autoreply_email?
    return self.send_autoreply == true && self.autoreply_text.present?
  end

  def create_auto_reply_service(task)
    text = self.autoreply_text || ''
    reply_to_message = task.messages.first
    if task.present? && text.present?
      text = text.gsub("\n", '<br/>')
      previous_message = "#{reply_to_message[:description]}".gsub("\n", '<br/>').gsub('<br/>', '<br/>> ')
      text = "#{text} <br/> <br/> #{previous_message}"







      # text = text.gsub('\n', '<br/>')
      # text = "#{text} <br/> <br/> #{reply_to_message[:description]}"
      # text = text.gsub("\n", '<br/>')
      # text = text.gsub('<br/>', '<br/>> ')








      params = ActionController::Parameters.new({
        reply:
        {
          title:           self.autoreply_email_subject.present? ? self.autoreply_email_subject : "auto-reply: #{reply_to_message[:title]}",
          description:     text,
          to:              reply_to_message[:from],
          # in_reply_to_id:  reply_to_message[:id],
          is_internal:     reply_to_message.try(:is_internal?) || false,
          need_send_email: true
        }
      })
      task_service = ::TaskService.new(task, params).build_message_and_send_reply
    end
  end

  def self.get_classname_by_channel_type(channel_type)
    case channel_type
    when 'email' then 'MediaChannel::Email'
    when 'web_form' then 'MediaChannel::WebForm'
    when 'internal' then 'MediaChannel::Internal'
    when 'call' then 'MediaChannel::Call'
    when 'chat' then 'MediaChannel::Chat'
    when 'sms' then 'MediaChannel::Sms'
    when 'agent' then 'MediaChannel::Agent'
    else nil
    end
  end

  def self.get_channel_type_by_classname(channel_type)
    case channel_type
    when 'MediaChannel::Email' then 'email'
    when 'MediaChannel::WebForm' then 'web_form'
    when 'MediaChannel::Internal' then 'internal'
    when 'MediaChannel::Call' then 'call'
    when 'MediaChannel::Chat' then 'chat'
    when 'MediaChannel::Sms' then 'sms'
    else nil
    end
  end

end
