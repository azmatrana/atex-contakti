class ServiceChannel < ActiveRecord::Base
  acts_as_paranoid
  acts_as_taggable_on :skills
  belongs_to :company

  has_one :email_media_channel, class_name: 'MediaChannel::Email'
  has_one :web_form_media_channel, class_name: 'MediaChannel::WebForm'
  has_one :internal_media_channel, class_name: 'MediaChannel::Internal'
  has_one :call_media_channel, class_name: 'MediaChannel::Call'
  has_one :chat_media_channel, class_name: 'MediaChannel::Chat'
  has_one :sip_media_channel, class_name: 'MediaChannel::Sip'
  has_one :sms_media_channel, class_name: 'MediaChannel::Sms'
  has_one :agent_media_channel, class_name: 'MediaChannel::Agent'

  has_one :user # is it actual?
  belongs_to :owner_user, class_name: 'User' # if this channel is agent's private than it for this user

  has_and_belongs_to_many :users
  has_and_belongs_to_many :locations
  has_and_belongs_to_many :reports, dependent: :destroy

  has_many :tasks, dependent: :destroy
  has_many :chat_records, dependent: :destroy
  has_many :sms_templates, dependent: :destroy
  has_many :media_channels, dependent: :destroy
  has_many :campaigns, dependent: :destroy
  has_many :chatbot_stats, class_name: 'Chatbot::Stat', dependent: :destroy
  has_many :orders, class_name: 'Chatbot::Order', dependent: :destroy

  accepts_nested_attributes_for :email_media_channel, :web_form_media_channel, update_only: true
  accepts_nested_attributes_for :call_media_channel, update_only: true
  accepts_nested_attributes_for :chat_media_channel, allow_destroy: true
  accepts_nested_attributes_for :sip_media_channel, allow_destroy: true
  accepts_nested_attributes_for :internal_media_channel, allow_destroy: true
  accepts_nested_attributes_for :sms_media_channel
  accepts_nested_attributes_for :locations
  accepts_nested_attributes_for :users

  include SlaAlertable
  include WeeklySchedulable

  before_validation :validate_alert_levels, unless: :user
  validates :name, :locations, presence: true, unless: :user

  scope :for_company, lambda { |company_id| where(company_id: company_id) }

  scope :shared, -> { where user_id: nil }
  scope :private_channels, -> { where.not user_id: nil }

  def agent_private?
    !!user_id
  end

  def sms_media_channel
    super || create_sms_media_channel
  end

  def run_all_test_checks
    %i(email web_form).each do |key|
      media_channel = __send__("#{key}_media_channel")
      next unless media_channel
      media_channel.run_test_check
    end
  end

  def get_active_media_channel_types
    %i[email web_form call internal].select do |c|
      media_channel = __send__("#{c}_media_channel")
      media_channel && media_channel.active? && !media_channel.broken?
    end
  end

  def agent_sms_templates
    @agent_sms_templates ||= begin
      sms_templates = ::SmsTemplate.arel_table
      ::SmsTemplate.where(
        sms_templates[:kind].eq(:agent).and(
          sms_templates.grouping(
            sms_templates[:service_channel_id].eq(self.id).and(sms_templates[:visibility].eq('service_channel'))
          ).or(
            sms_templates.grouping(
              sms_templates[:company_id].eq(self.company_id).and(sms_templates[:visibility].eq('company'))
            )).or(
            sms_templates.grouping(
              sms_templates[:visibility].eq('location').and(sms_templates[:location_id].in(self.locations.map(&:id)))
            ))
        )
      )
    end
  end

  def manager_sms_templates
    self.sms_templates.for_manager
  end

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

  def signature
    read_attribute(:signature).nil? ? '' : read_attribute(:signature).gsub(/[\r]/, '').gsub(/[\n]/, "<br>")
  end

end
