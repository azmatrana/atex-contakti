# == Schema Information
#
# Table name: companies
#
#  id                :integer          not null, primary key
#  name              :string(100)      default(""), not null
#  street_address    :string(250)      default(""), not null
#  zip_code          :string(100)      default(""), not null
#  city              :string(100)      default(""), not null
#  code              :string(100)      default(""), not null
#  contact_person_id :integer
#  created_at        :datetime
#  updated_at        :datetime
#  time_zone         :string(255)      default("Helsinki"), not null
#  inactive          :boolean          default(FALSE)
#

class Company < ActiveRecord::Base
  SMS_PROVIDERS = %w[Labyrintti Tavoittaja]
  acts_as_taggable_on :skills, :flags, :generic_tags
  has_many :users, dependent: :destroy
  has_many :stats, class_name: 'Company::Stat', dependent: :destroy
  has_many :sms_templates, dependent: :destroy
  has_many :service_channels, dependent: :destroy
  has_many :tasks, through: :service_channels
  has_many :preferences, dependent: :destroy
  has_many :media_channels, through: :service_channels
  has_many :reports, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :campaigns, dependent: :destroy
  has_many :campaign_items, through: :campaigns
  has_many :agent_call_logs, through: :users
  has_many :questions
  has_many :intents
  has_many :answers
  has_many :template_replies
  has_many :entities
  has_many :question_templates
  has_many :files, class_name: 'CompanyFile', foreign_key: 'company_id'
  has_many :basic_templates
  has_many :products, class_name: 'Chatbot::Product', foreign_key: 'company_id'
  has_many :orders, class_name: 'Chatbot::Order', foreign_key: 'company_id'
  has_many :shipment_methods, dependent: :destroy
  has_many :cart_email_templates, dependent: :destroy
  has_many :chatbot_stats, class_name: 'Chatbot::Stat', foreign_key: 'company_id'
  has_many :vats
  has_many :third_party_tools

  validates :name, :code, :time_zone, :currency, presence: true
  validates_inclusion_of :sms_provider, in: SMS_PROVIDERS, allow_nil: true

  before_validation :check_sms_provider_presents
  before_destroy :destroy_paranoid_relations
  validate :check_wit_chatbot_response
  # validates_format_of :kimai_tracker_api_url, :with => /\A(https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\z/ix
  validates_format_of :kimai_tracker_api_url, :with => /\A(https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\z/ix, allow_blank: true
  # validates :kimai_tracker_api_url
  after_commit :create_cart_email_templates, on: :create

  CART_EMAIL_TEMPLATES_OPTIONS = [
    { template_for: "order_placed", subject: I18n.translate('tags.order_placed'), body: "{{products}}" },
    { template_for: "order_payment_link", subject: I18n.translate('tags.payment_link'), body: "{{payment_link}}" },
    { template_for: "terms_and_conditions", subject: I18n.translate('tags.terms_and_conditions'), body: I18n.translate('tags.terms_and_conditions') },
  ]

  def create_cart_email_templates
    CART_EMAIL_TEMPLATES_OPTIONS.each do |option|
      self.cart_email_templates.create(option)
    end
  end

  def current_stat
    @current_stat ||= stats.where(date: ::Time.current.beginning_of_month.to_date).first_or_create
  end

  def agents
    users.joins(:roles).where('roles.name' => 'agent')
  end

  def active?
    !self.inactive
  end

  def deactivate!
    self.inactive = true
    self.save!
  end

  def activate!
    self.inactive = false
    self.save!
  end

  def method_missing(m, *args, &block)
    if m =~ /prefers_having_.*\?/
      ::Preference.send(m.to_s, self)
    else
      super
    end
  end

  def find_skills(query='')
    skills.where("name LIKE ?", "#{query}%").pluck(:name)
  end

  def find_task_generic_tags(query='')
    ActsAsTaggableOn::Tag.find_by_sql([
      <<-EOQ, self[:id], "#{query}%"
        SELECT DISTINCT(tags.name), tags.taggings_count FROM tags
          JOIN taggings         ON taggings.tag_id = tags.id
          JOIN tasks            ON taggings.taggable_id = tasks.id
          JOIN service_channels ON service_channels.id = tasks.service_channel_id
        WHERE taggings.taggable_type = 'Task'
          AND taggings.context = 'generic_tags'
          AND service_channels.company_id = ?
          AND tags.name LIKE ?
        ORDER BY tags.taggings_count DESC
        LIMIT 10
      EOQ
    ]).collect(&:name)
  end

  # Yuk, SQL
  def tag_usage_count
    tag_counts = {}

    ActsAsTaggableOn::Tag.find_by_sql([
      <<-EOQ, self[:id]
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
      <<-EOQ, self[:id], 'agent'
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

  def have_chatbot?
    self.wit_chatbot_token.present? && self.have_valid_wit_chatbot_token == true
  end

  def check_wit_chatbot_response
    if self.wit_chatbot_token.present? && self.wit_chatbot_token_changed?
      self.update_attribute(:have_valid_wit_chatbot_token, false)
      client = Wit.new(access_token: self.wit_chatbot_token)
      res = client.message("Test the response") rescue nil
      if res.nil?
        puts "valid-------------------------------------"
        errors.add(:wit_chatbot_token, "Not a valid wit chatbot token")
      else
        puts "error-------------------------------------"
        self.update_attribute(:have_valid_wit_chatbot_token, true)
      end
    end
  end

  def is_ad_finland_company?
    return self.spare_parts_api_key.present?
  end

  private

  def check_sms_provider_presents
    self.sms_provider = nil if sms_provider.blank?
  end

  def destroy_paranoid_relations
    service_channels.each do |service_channel|
      service_channel.tasks.find_each do |task|
        task.messages.each do |message|
          message.attachments.each do |attachment|
            attachment.really_destroy!
          end
          message.really_destroy!
        end
        task.really_destroy!
      end
      service_channel.media_channels.each do |media_channel|
        media_channel.really_destroy!
      end
      service_channel.really_destroy!
    end
  end
end
