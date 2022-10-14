class Message < ActiveRecord::Base
  acts_as_paranoid

  SEARCH_KEYS = %i(from to title description)

  belongs_to :task
  belongs_to :user

  has_many :attachments, class_name: 'Message::Attachment', dependent: :destroy

  scope :for_period, lambda { |starts_at, ends_at| where(['created_at > ? AND created_at < ?', starts_at, ends_at]) }
  scope :email_channel, -> { where(channel_type: :email) }
  scope :web_form_channel, -> { where(channel_type: :web_form) }
  scope :internal_channel, -> { where(channel_type: :internal) }
  scope :call_channel, -> { where(channel_type: :call) }
  scope :chat_channel, -> { where(channel_type: :chat) }
  scope :sms_channel, -> { where(channel_type: :sms) }
  # Notice! This will return messages in soft deleted tasks as well
  scope :in_media_channel, lambda { |media_channel_id| joins('inner join tasks on tasks.id = messages.task_id').where(tasks: { media_channel_id: media_channel_id }) }
  scope :in_service_channel, lambda { |service_channel_id| joins('inner join tasks on tasks.id = messages.task_id').where(tasks: { service_channel_id: service_channel_id }) }

  validates :to, presence: true
  validates :channel_type, inclusion: { in: %w(email web_form call chat internal sms) }
  #validates :to, phony_plausible: true, if: :sms?
  validates :description, presence: true, if: -> { need_send_email || need_send_sms || need_push_to_browser }
  validates :title, presence: true, if: -> { channel_type == 'email' && !sms? }

  validates :message_uid, uniqueness: { scope: [:task_id] }, allow_nil: true
  after_commit :call_translate_service, on: :create

  attr_accessor :need_push_to_browser,
                :need_send_email,
                :need_send_sms

  store_accessor :settings, :cc, :bcc

  # Before and around callbacks are called in the order that they are set;
  # after callbacks are called in the reverse order.
  # We will push to browser any changes what we will do
  after_commit :send_email, if: -> { need_send_email }
  after_commit :send_sms, if: -> { need_send_sms }
  after_commit :push_message_to_browser, if: -> { need_push_to_browser }

  before_create :clone_attachments_on_forward

  # Ransack
  ransacker :search_cond do |parent|
    Arel::Nodes::NamedFunction.new('LOWER',
      [Arel::Nodes::NamedFunction.new('concat_ws',
        [' ', *SEARCH_KEYS.map { |x| parent.table[x] }])])
  end

  def get_signature
    "<br/><br/>[Task ID: #{self.task.uuid}]<br/>[Message ID: #{self.id}#{self.number}]"
  end

  def from_email
    from[/(?<=<)[\w@\.]+(?=>)/] || from
  end

  def active_model_serializer
    ::MessageSerializer
  end

  def push_message_to_browser
    ::DanthesPushWorker.perform_async(self.class.name, id)
  end

  def add_signature_to_description
    self.description = description + get_signature
  end

  def send_sms
    sms_sender = self.task.service_channel.call_media_channel.try :sms_sender
    ::SmsSenderWorker.perform_async(
      sms_sender,
      self.to,
      self.description,
      self.task.company_id
    ) if self.task.company.sms_provider
  end

  def send_email
    ::EmailSenderWorker.perform_async(id)
  end

  def clone_attachments_on_forward
    if in_reply_to_id && is_internal?
      forward_message = self.task.messages.find(in_reply_to_id)
      forward_message.attachments.each do |attachment|
        self.attachments.build(
          file_name:    attachment.file_name,
          file_size:    attachment.file_size,
          content_type: attachment.content_type,
          file:         ::AttachmentStringIO.new(attachment.file_name, attachment.file.read)
        )
      end
    end
  end

  def call_recording_attachment
    self.attachments.call_recordings.first
    rescue
    nil
  end

  def call_recording_content
    self.call_recording_attachment.file.read
    rescue
    ""
  end

  def call_translate_service
    call_recording = self.call_recording_attachment
    if call_recording.present?
      if self.task.company.allow_call_translation?
        ::CallTranslatorWorker.perform_async(self.id)
      end
    end
  end

  class << self
    def signature_regex
      /\[Task ID: (?<task_id>[0-9abcdef\-]{36})\]\n\[Message ID: (?<message_id>[0-9abcdef\-]{36})(?<message_number>[0-9]+)/
    end

    def task_signature_regex
      /\[Task ID: (?<task_id>[0-9abcdef\-]{36})\]/
    end

    def message_signature_regex
      /\[Message ID: (?<message_id>[0-9abcdef\-]{36})(?<message_number>[0-9]+)/
    end
  end
end
