require 'redis'

class User < ActiveRecord::Base
  acts_as_taggable_on :skills, :generic_tags

  SEARCH_KEYS = %i(first_name last_name mobile email)
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable
  rolify

  attr_accessor :created_by_manager, :smtp_settings, :imap_settings
#  attr_accessor :password, :password_confirmation, :created_by_manager

  belongs_to :company
  belongs_to :default_location, :class_name => '::Location' # Cost center / Kustannuspaikka
  belongs_to :service_channel
  belongs_to :sip_settings, dependent: :destroy

  has_many :agent_campaigns, dependent: :destroy, foreign_key: 'agent_id'
  has_many :campaigns, through: :agent_campaigns
  has_many :channel_campaigns, through: :service_channels, source: :campaigns

  # private agent channel
  has_one :media_channel, dependent: :destroy
  has_one :private_service_channel, class_name: 'ServiceChannel'

  has_and_belongs_to_many :service_channels
  has_and_belongs_to_many :locations
  has_and_belongs_to_many :managed_locations, class_name: '::Location', join_table: 'locations_managers', foreign_key: 'manager_id'
  has_and_belongs_to_many :reports

  has_many :timelogs, dependent: :destroy
  has_many :messages
  has_many :media_channels, ->(user) { where(media_channels: { type: user.media_channel_klasses }) },
           class_name: 'MediaChannel',
           through: :service_channels

  has_many :sessions, class_name: 'User::Session', dependent: :destroy

  has_many :tasks, through: :media_channels
  has_many :agent_call_logs, foreign_key: 'agent_id'
  has_many :contacts, dependent: :destroy, foreign_key: 'agent_id'
  has_many :call_histories
  has_many :follows, dependent: :destroy
  has_many :recepient_emails, dependent: :destroy
  accepts_nested_attributes_for :service_channels
  accepts_nested_attributes_for :locations
  accepts_nested_attributes_for :sip_settings

  validates :first_name, :last_name, :email, :company_id, presence: true
  validates :password, presence: true, unless: -> { self.persisted? }

  delegate :service_channels, to: :company, prefix: true
  
  has_one :kimai_detail, :class_name => 'Kimai::KimaiDetail'
  delegate :kimai_tracker_api_url, to: :company, allow_nil: true
  delegate :tracker_email, to: :kimai_detail, allow_nil: true
  delegate :tracker_auth_token, to: :kimai_detail, allow_nil: true


  scope :for_company, lambda { |company_id| where(:company_id => company_id) }
  scope :busy,   -> { joins(:sip_settings).where(in_call: true, is_online: true) }
  scope :free,   -> { joins(:sip_settings).where(in_call: false, is_online: true) }

  after_commit :after_agent_creation_hook, on: :create, if: -> { self.created_by_manager }
  # after_save :online_notifier, if: :is_online_changed?

  # Ransack
  ransacker :search_cond do |parent|
    Arel::Nodes::NamedFunction.new('LOWER',
      [Arel::Nodes::NamedFunction.new('concat_ws',
        [' ', *SEARCH_KEYS.map { |x| parent.table[x] }])])
  end

  ransacker :full_name, formatter: proc { |v| v.mb_chars.downcase.to_s } do |parent|
    Arel::Nodes::NamedFunction.new('LOWER',
      [Arel::Nodes::NamedFunction.new('concat_ws',
        [' ', parent.table[:first_name], parent.table[:last_name]])])
  end

  ransacker :full_name_format, formatter: proc { |v| v.mb_chars.downcase.to_s } do |parent|
    Arel::Nodes::NamedFunction.new('LOWER',
      [Arel::Nodes::NamedFunction.new('concat_ws',
        [' ', parent.table[:last_name], parent.table[:first_name]])])
  end

  def agent_media_channel
    media_channel || MediaChannel::Agent.create(user_id: id)
  end

  def prepare_agent_channels
    # create private media and service channels for agent
    agent_media_channel.service_channel
  end

  def unseen_tasks_count
    last_seen = self.last_seen_tasks || DateTime.new
    new_tasks = self.tasks.where(:created_at => last_seen..DateTime.current).where(:state => 'new').where(:updated_at => nil).count
    # TODO: How crappy is this query, rails dudes?
    updated_tasks = self.tasks.where.not(:updated_at => nil).where(:updated_at => last_seen..DateTime.current).where(:state => 'new').count
    new_tasks + updated_tasks
  end

  def user_skills
    skills.pluck(:name)
  end

  def low_priority_service_channels
    low_priorities = Priority.where(priority_value: 1).pluck(:tag_id)
    tags = ActsAsTaggableOn::Tag.find(low_priorities).map(&:name)
    service_channels = ServiceChannel.tagged_with(tags, any: true)
    service_channels.pluck(:name)
  end

  def in_low_priority
    !(low_priority_service_channels & service_channels.pluck(:name)).empty?
  end

  def task_matched_skills? (task)
    if task.present?
      (user_skills & task.skills.pluck(:name)).present?
    else
      false
    end
  end

  def created_by_manager!
    @created_by_manager = 1
  end

  def full_name
    "#{self.first_name} #{self.last_name}"
  end

  def full_name_format
    "#{self.last_name}, #{self.first_name}"
  end

  def get_random_password
    ('%8s' % rand(10_000_000).to_s).gsub(/ /, rand(9).to_s)
  end

  def after_database_authentication
    # tracking online status for managers as well
    self.update_attributes({
      is_online: true, is_working: true, started_working_at: ::Time.current
    })
    if self.has_role? :agent
      self.timelogs.create!
    end
  end

  def media_channel_klasses
    (['agent']+media_channel_types.select do |type|
      type.present?
    end).map do |type|
      ::MediaChannel.get_classname_by_channel_type(type)
    end
  end

  def after_agent_creation_hook
    @created_by_manager = false
    add_role :agent
    # TODO: move to background
    send_reset_password_instructions
  end


  def online_notifier
    if company
     ::Danthes.publish_to "/company/#{company.id}/online", {:online => is_online.to_s}
    end
  end

  def agent_in_call_status_notifier
    ::Danthes.publish_to "/in_call_status/#{self.id.to_s}", {in_call: self.in_call.to_s, online: self.is_online.to_s}
  end


  # Generates (if blank) and returns 'authentication_token'
  # Mainly called from Api::V1::SessionsController#create
  def authentication_token!
    if authentication_token.blank?
      update_attribute :authentication_token, User.generate_authentication_token
    end

    authentication_token
  end

  def active_for_authentication?
    super && (self.company ? self.company.active? : true)  # i.e. super && self.is_active
  end

  def smtp_settings
    if self.service_channel.nil?
      self.service_channel = ::ServiceChannel.new
    end

    if self.service_channel.email_media_channel.nil?
      self.service_channel.email_media_channel = ::MediaChannel::Email.new
    end

    if self.service_channel.email_media_channel.smtp_settings.nil?
      self.service_channel.email_media_channel.smtp_settings = SmtpSettings.new
    end

    self.service_channel.email_media_channel.smtp_settings
  end

  def imap_settings
    if self.service_channel.nil?
      self.service_channel = ::ServiceChannel.new
    end

    if self.service_channel.email_media_channel.nil?
      self.service_channel.email_media_channel = ::MediaChannel::Email.new
    end

    if self.service_channel.email_media_channel.imap_settings.nil?
      self.service_channel.email_media_channel.imap_settings = ImapSettings.new
    end

    self.service_channel.email_media_channel.imap_settings
  end

  def smtp_settings=(smtp_settings)
    if self.service_channel.nil?
      self.service_channel = ::ServiceChannel.new
      self.service_channel.user = self
    end

    if self.service_channel.email_media_channel.nil?
      self.service_channel.email_media_channel = ::MediaChannel::Email.new
    end

    if smtp_settings.is_a? Hash
      if self.service_channel.email_media_channel.smtp_settings.nil?
        self.service_channel.email_media_channel.smtp_settings = SmtpSettings.new
      end

      self.service_channel.email_media_channel.smtp_settings.update_attributes(smtp_settings)
      self.service_channel.email_media_channel.save
    else
      self.service_channel.email_media_channel.smtp_settings = smtp_settings
    end
  end

  def imap_settings=(imap_settings)
    if self.service_channel.nil?
      self.service_channel = ::ServiceChannel.new
      self.service_channel.user = self
    end

    if self.service_channel.email_media_channel.nil?
      self.service_channel.email_media_channel = ::MediaChannel::Email.new
    end

    if imap_settings.is_a? Hash
      if self.service_channel.email_media_channel.imap_settings.nil?
        self.service_channel.email_media_channel.imap_settings = ImapSettings.new
      end

      self.service_channel.email_media_channel.imap_settings.update_attributes(imap_settings)
      self.service_channel.email_media_channel.save
    else
      self.service_channel.email_media_channel.imap_settings = imap_settings
    end
  end

  def set_online(is_online)
    attrs_to_update = { is_online: is_online }
    if is_online and self.has_role? :agent
      self.timelogs.create! if self.timelogs.last.nil?
      # self.went_offline_at = Time.now
      minutes_paused = Helpers::TimeFormat.get_minutes_to(self.went_offline_at)
      self.timelogs.last.increment!(:minutes_paused, minutes_paused)

      redis = Redis.new
      danthes_clear_user_ids = 'danthes:clear_user_ids'
      clear_ids = JSON.parse(redis.get(danthes_clear_user_ids) || '[]')
      if clear_ids.delete(self.id)
        redis.set(danthes_clear_user_ids, clear_ids.to_json)
      end
    else
      attrs_to_update.merge!({ went_offline_at: ::Time.current })
    end
    self.update_attributes attrs_to_update
  end

  def set_in_call(is_in_call)
    attrs_to_update = { in_call: is_in_call }
    self.update_attributes attrs_to_update
  end

  def self.generate_authentication_token
    SecureRandom.urlsafe_base64(27) # 27 random bytes => 27 * 4/3 = 36 digits (base64)
  end

  def signature
    read_attribute(:signature).nil? ? '' : read_attribute(:signature).gsub(/[\r]/, '').gsub(/[\n]/, "<br>")
  end

  def from_emails
    from_emails = []
    from_emails << email
    from_emails << email_without_dot(email)
    from_emails << imap_settings.from_email
    from_emails << email_without_dot(imap_settings.from_email)
    service_channels.each do |service_channel|
      from_emails << service_channel.try(:email_media_channel).try(:imap_settings).try(:from_email)
      from_emails << email_without_dot(service_channel.try(:email_media_channel).try(:imap_settings).try(:from_email))
    end
    from_emails.compact.uniq
  end

  def email_without_dot(email)
    return "" if email.blank?
    username, email_provider = email.split('@')
    [username.gsub('.', ''), '@', email_provider].join
  end
  # Yuk, SQL
  def tag_usage_count
    tag_counts = {}

    ActsAsTaggableOn::Tag.find_by_sql([
      <<-EOQ, company_id
        SELECT tags.name, taggings.context, COUNT(tasks.id) AS task_count FROM tags
          JOIN taggings         ON taggings.tag_id = tags.id
          JOIN tasks            ON taggings.taggable_id = tasks.id
          JOIN service_channels ON service_channels.id = tasks.service_channel_id
        WHERE taggings.taggable_type = 'Task'
          AND service_channels.company_id = ?
        GROUP BY tags.name, taggings.context
      EOQ
    ]).each do |result|
      tag_counts[result.context.to_sym] ||= {}
      tag_counts[result.context.to_sym][result.name] ||= {}
      tag_counts[result.context.to_sym][result.name][:tasks] = result.task_count
    end

    ActsAsTaggableOn::Tag.find_by_sql([
      <<-EOQ, company_id, 'agent'
        SELECT tags.name, taggings.context, COUNT(users.id) AS user_count FROM tags
          JOIN taggings         ON taggings.tag_id = tags.id
          JOIN users            ON users.id = taggings.taggable_id
          JOIN users_roles      ON users_roles.user_id = users.id
          JOIN roles            ON roles.id = users_roles.role_id
        WHERE taggings.taggable_type = 'User'
          AND users.company_id = ?
          AND roles.name = ?
        GROUP BY tags.name, taggings.context
      EOQ
    ]).each do |result|
      tag_counts[result.context.to_sym] ||= {}
      tag_counts[result.context.to_sym][result.name] ||= {}
      tag_counts[result.context.to_sym][result.name][:agents] = result.user_count
    end

    tag_counts
  end

  def possible_service_channels
    service_channel_ids = self.service_channels.pluck(:id)
    service_channel_ids |= self.locations.collect(&:service_channels).collect(&:ids).flatten
    service_channel_ids
  rescue
    []
  end

  def sip_user_name
    self.try(:sip_settings).try(:user_name)
  end

  def toggle_agent_call_settings(setting_action)
    if setting_action.present?
      case setting_action
      when "is_dnd_active"
        self.is_dnd_active = !self.is_dnd_active
      when "is_transfer_active"
        self.is_transfer_active = !self.is_transfer_active
      when "is_acd_active"
        self.is_acd_active = !self.is_acd_active
      when "is_follow_active"
        self.is_follow_active = !self.is_follow_active
      else
        "N/A"
      end

      self.save
    end
  end

  def get_campaigns
    ::Campaign.where(id: (self.campaigns.pluck(:id) + self.channel_campaigns.pluck(:id)))
  end

  def tracker_details_present?
    self.kimai_tracker_api_url.present? && self.tracker_email.present? && self.tracker_auth_token.present?
  end
end
