class Task < ActiveRecord::Base
  include TasksHelper

  acts_as_paranoid
  # Tags:
  # * :skills tags are for example "linux", users can add "linux" to their skills and then find
  #   tasks that are relevant to them. The allowed tags will be predefined.
  # * :flags tags are task flags such as "urgent", "spam", "missed-sla"
  # * :generic_tags are just like skill tags but free text.
  #
  # There could also be :problems tag scope for marking tasks to be related to known problems
  # such as "forgot-password" or "server-crash-2016-08"
  acts_as_taggable_on :skills, :flags, :generic_tags

  include AASM
  include TimeScopes

  attr_accessor :task_priority
  attr_accessor :dont_push_to_browser


  has_paper_trail class_name: 'TaskVersion'

  belongs_to :customer, inverse_of: :tasks
  belongs_to :service_channel, class_name: 'ServiceChannel'
  belongs_to :media_channel
  belongs_to :agent, class_name: '::User', foreign_key: 'assigned_to_user_id'
  belongs_to :closed_by_user, class_name: '::User'
  belongs_to :send_by_user, class_name: '::User'

  delegate :users, to: :media_channel

  has_many :messages, -> { order('created_at DESC') }, dependent: :destroy
  has_one :draft, autosave: true, dependent: :destroy
  has_many :follows, autosave: true, dependent: :destroy

  accepts_nested_attributes_for :messages, allow_destroy: true

  has_one :note, class_name: 'Task::Note', autosave: true, dependent: :destroy
  has_one :order, class_name: 'Chatbot::Order', foreign_key: 'task_id', dependent: :destroy
  belongs_to :campaign_item
  has_one :tracker_tracker_detail, :class_name => 'Tracker::TrackerDetail'

  scope :email_channel, -> { joins(:media_channel).merge(::MediaChannel.emails) }
  scope :web_form_channel, -> { joins(:media_channel).merge(::MediaChannel.web_forms) }
  scope :internal_channel, -> { joins(:media_channel).merge(::MediaChannel.internals) }
  scope :call_channel, -> { joins(:media_channel).merge(::MediaChannel.calls) }
  scope :chat_channel, -> { joins(:media_channel).merge(::MediaChannel.chat) }
  scope :sms_channel, -> { joins(:media_channel).merge(::MediaChannel.sms) }
  scope :unsolved, -> { where.not(state: :ready) }
  scope :unsolved_new, -> { unsolved.where(hidden: nil) }
  scope :from_softfone, -> { where(is_softfone_ticket: true)}
  scope :in_bound_email_sms_channel, -> (ids) {includes(:media_channel).where.not(media_channels: {type: ["MediaChannel::Email","MediaChannel::Sms"]},send_by_user_id: ids)}

  default_scope -> do
    where(hidden: nil)
  end

  before_save :check_assign_changing
  before_save :convert_generic_tags_to_skills

  after_commit :call_post_to_wit_api, on: :create
  after_commit :push_task_to_browser
  after_commit :call_campaign_update, on: :create

  attr_accessor :email_to_addresses, :email_subject, :email_message, :email_lang

  ransacker :data_search do |parent|
    Arel::Nodes::NamedFunction.new('LOWER', [ Arel::Nodes::InfixOperation.new('->>', parent.table[:data], 'caller_name') ])
  end

  aasm column: 'state' do
    state :new, initial: true
    state :open, :before_enter => [:start_timer, :clear_result]
    state :waiting, :before_enter => :update_time_spent
    state :ready, :before_enter => [:update_time_spent, :update_turnaround_time]

    event :start, guard: :is_not_call? do
      transitions from: [:new, :waiting], to: :open
    end
    event :pause, guard: :is_not_call? do
      transitions from: [:new, :open], to: :waiting
    end
    event :lock, guard: :is_call? do
      transitions from: :new, to: :waiting
    end
    event :unlock, guard: :is_call? do
      transitions from: :waiting, to: :new
    end
    event :close do
      transitions from: [:new, :open, :waiting], to: :ready
    end
    event :restart do
      transitions from: :ready, to: :new
    end
    event :open do
      transitions from: :new, to: :open
    end
    event :renew do
      transitions from: [:open, :waiting, :ready], to: :new
    end
  end

  def inbound?
    messages.where('messages.inbound IS TRUE OR messages.in_reply_to_id IS NOT NULL OR messages.channel_type = ?', 'web_form').present?
  end

  def in_agent_private_channel?
    service_channel.agent_private?
  end

  def use_assigned_user_email_settings
      super || service_channel.try(:agent_private?)
  end

  def service_channel
    super || media_channel.try(:service_channel)
  end

  def company_id
    @company_id ||= service_channel ? service_channel.company_id : media_channel.try(:company_id)
  end

  def company
    @company ||= Company.find(company_id)
  end

  def include_messages
    @include_messages ||= false
  end

  def include_messages=(i)
    @include_messages = i
  end

  def self.main_states
    self.aasm.states.map(&:name) - [:archived]
  end

  def is_not_call?
    @is_not_call ||= self.media_channel and !self.media_channel.call?
  end

  def is_call?
    !is_not_call?
  end

  def positive?
    self.result == 'positive'
  end

  def neutral?
    self.result == 'neutral'
  end

  def negative?
    self.result == 'negative'
  end

  def start_timer
    return if is_call?
    self.last_opened_at = ::Time.current
    self.opened_at = ::Time.current unless self.opened_at
  end

  def clear_result
    self.result = ''
  end

  def current_minutes_spent
    return 0 if !self.last_opened_at
    ((::Time.current - self.last_opened_at) / 60).floor
  end

  def total_minutes_spent
    self.minutes_spent + self.current_minutes_spent
  end

  def update_time_spent
    self.minutes_spent = self.total_minutes_spent
  end

  def update_turnaround_time
    return unless self.opened_at
    self.turnaround_time = ((::Time.current - self.opened_at) / 60).floor
  end

  def refresh_waiting_timeout
    update_attribute(:assigned_at, ::Time.current)
  end

  def change_service_channel(service_channel)
    if self.service_channel_id != service_channel.id
      self.service_channel_id = service_channel.id
      self.save!
    end
  end

  def assign_to_agent(agent)
    self.update_attribute(:assigned_to_user_id, agent.nil? ? nil : agent.id)
  end


  def weekly_schedule
    if media_channel && media_channel.weekly_schedule
      media_channel.weekly_schedule
    else
      if service_channel
        if service_channel.locations.first
          service_channel.weekly_schedule ? service_channel.weekly_schedule : service_channel.locations.first.weekly_schedule
        else
          ws = WeeklySchedule.new
          ws.open_full_time = true
          ws
        end
      end
    end
  end

  def count_minutes_spent
    stop_counting_at = self.ready? ? self.updated_at : ::Time.current
    if weekly_schedule
      weekly_schedule.total_work_time_between(self.created_at, stop_counting_at)
    else
      ((stop_counting_at - self.created_at) / 60).floor
    end
  end

  #Use alert level from Media Channel if configured, otherwise Service Channel
  def minutes_till_alert(alert_level)
    (self.weekly_schedule ? self.__send__("#{alert_level}_alert_limit") : total_time_until_red_alert) - self.count_minutes_spent
  end

  def total_time_until_red_alert
    alertable('red').try(:red_alert_limit_in_hours).to_i * 60
  end

  def red_alert_limit
    alert_date = self.red_alert_date

    if alert_date.present?
      weekly_schedule.total_work_time_between(self.created_at, alert_date)
    else
      Float::INFINITY
    end
  end

  def yellow_alert_limit
    alert_date = self.yellow_alert_date

    if alert_date.present?
      weekly_schedule.total_work_time_between(self.created_at, alert_date)
    else
      Float::INFINITY
    end
  end


  def minutes_till_yellow_alert
    minutes_till_alert 'yellow'
  end

  def minutes_till_red_alert
    minutes_till_alert 'red'
  end
  def red_alert_or_ready_date
    self.ready? ? self.updated_at : red_alert_date
  end
  def alertable(type)
    media_channel.try(:has_alert_of_level?, type) ? media_channel : service_channel
  end
  def red_alert_date
    logger.info "======task id======#{id}======"
    weekly_schedule.date_after_working_time({days: alertable('red').red_alert_days, hours: alertable('red').red_alert_hours}, self.created_at, media_channel.try(:type))
  rescue
    nil
  end

  def yellow_alert_date
    weekly_schedule.date_after_working_time({days: alertable('yellow').yellow_alert_days, hours: alertable('yellow').yellow_alert_hours}, self.created_at, media_channel.try(:type))
  rescue
    nil
  end

  def active_model_serializer
    ::TaskSerializer
  end

  def check_assign_changing
    if assigned_to_user_id_changed? || (state_changed? && state == 'waiting')
      self.assigned_at = ::Time.current
    end
  end

  def self.should_unlock
    waiting.where('assigned_at <= ?', unlock_waiting_after.ago)
  end

  def self.to_warn_about_unlock
    waiting.where('assigned_at <= ? AND assigned_at > ?', unlock_waiting_warn.ago, unlock_waiting_after.ago)
  end

  def self.unlock_waiting_after
    10.minutes
  end

  def self.unlock_waiting_warn
    unlock_waiting_after - 5.minutes
  end

  def call_post_to_wit_api
    check_priority_alarm
  end

  def push_task_to_browser
    # post_to_wit_api(self)
    unless self.dont_push_to_browser == true
      ::DanthesPushWorker.perform_async(self.class.name, self.id)
    end
  end

  def push_waiting_timeout_alert
    ::DanthesWaitingTaskTimeoutAlertWorker.perform_async(self.class.name, self.id)
  end

  def convert_generic_tags_to_skills
    (service_channel.company.skill_list & generic_tag_list).each do |convertible|
      skill_list.add(convertible)
      generic_tag_list.remove(convertible)
    end
    true
  rescue
    true
  end

  def check_priority_alarm
    task_skills = service_channel.company.skill_list & generic_tag_list
    task_skills << self.skill_list

    task_skills.flatten.uniq.each do |tag|
      ::PriorityAlarmWorker.perform_async(tag, self.id, self.service_channel.company_id)
    end
  end

  def skills_priority
    skills.map do |p|
      {
        name: p.name,
        priority: Priority.find_priority(company_id, p.id)
      }
    end
  end

  def task_priority
    priority = skills.map do |p|
      Priority.find_priority(company_id, p.id)
    end
    return priority.max
  end

  def max_skill_priority_object
    # it will return first prioriy having max priority_value value of task skills
    return Priority.where(company_id: self.company_id, tag_id: self.skills.pluck(:id)).order('priority_value DESC').first
  end

  def custom_task_priority(task_skills = [])
    priority = task_skills.map do |p|
      Priority.find_priority(company_id, p.id)
    end
    return priority.max
  end

  def service_channel_agent_ids
    channel_agents = service_channel.users.pluck(:id)

    location_agents = service_channel.locations.collect(&:users).collect(&:ids).flatten

    channel_agents | location_agents
  rescue
    []
  end

  def skills_matched_service_channel_agents(task_skills = [])
    return [] if true || [1,2,3].exclude?(self.custom_task_priority(task_skills))

    channels = service_channel.company.service_channels

    channel_agents = channels.collect(&:users).collect(&:ids).flatten

    location_agents = if self.task_priority == 2 && self.open_to_all == true
      channels.collect(&:locations).flatten
      .collect(&:users)
      .collect(&:ids)
      .flatten.uniq
    else
      []
    end

    channel_agents | location_agents
  rescue
    []
  end

  def call_campaign_update
    if (self.campaign_item)
      self.campaign_item.push_to_browser_refresh
    end
  end

end
