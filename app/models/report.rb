# == Schema Information
#
# Table name: reports
#
#  id                          :integer          not null, primary key
#  title                       :string(100)      default(""), not null
#  kind                        :string(20)       default(""), not null
#  starts_at                   :datetime
#  ends_at                     :datetime
#  company_id                  :integer
#  author_id                   :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  send_to_emails              :string(500)      default(""), not null
#  scheduled                   :string(255)      default(""), not null
#  last_sent_at                :datetime
#  media_channel_types         :text             default([]), is an Array
#  report_scope                :string(20)       default(""), not null
#  dashboard_layout_id         :integer
#  locale                      :string(20)
#  start_sending_at            :datetime
#  schedule_start_sent_already :boolean          default(FALSE), not null
#

# TODO: STI for Summary & Comparison reports

class Report < ActiveRecord::Base
  attr_accessor :show_all, :date_range

  belongs_to :company
  has_and_belongs_to_many :locations
  has_and_belongs_to_many :service_channels
  has_and_belongs_to_many :users
  belongs_to :author, class_name: 'User'
  belongs_to :dashboard_layout

  validates :title, :starts_at, :ends_at, presence: true

  accepts_nested_attributes_for :locations, update_only: true
  accepts_nested_attributes_for :service_channels, update_only: true
  accepts_nested_attributes_for :users, update_only: true

  scope :scheduled, -> { where.not(scheduled: '', send_to_emails: '') }

  def summary?
    self.kind == 'summary'
  end

  def comparison?
    self.kind == 'comparison'
  end

  def screenshot
    ::Rails.root.join('public', 'system', 'reports', "#{self.id}.png")
  end

  def pdf
    ::Rails.root.join('public', 'system', 'reports', "#{self.id}.pdf")
  end

  def screenshot_for_period(start_date, end_date)
    ::Rails.root.join('public', 'system', 'reports', "#{self.id}_#{start_date.strftime('%Y%m%d')}_#{end_date.strftime('%Y%m%d')}.png")
  end

  def tasks(type = self.kind)
    @tasks = ((@type == type) ? @tasks : ::Task.unscoped.joins(:service_channel, :media_channel).where(
      'service_channels.company_id' => self.company_id,
      :deleted_at => nil
    ))
    @type = type
    if self.starts_at && self.ends_at
      if type == 'comparison'
        @tasks = @tasks.for_period_updated_at(self.starts_at, self.ends_at)
      else
        @tasks = @tasks.for_period(self.starts_at, self.ends_at)
      end
    end
    unless self.show_all
      if type == 'summary'
        channel_types = self.media_channel_types.map { |c| ::MediaChannel.get_classname_by_channel_type(c) }
        @tasks = @tasks.joins(:service_channel => :locations).where('locations.id' => self.location_ids)
                       .where(service_channels: { id: self.service_channel_ids })
                       .joins(:media_channel).where(media_channels: { type: channel_types })
        @tasks = @tasks.ready if self.report_scope == 'closed'
      end
      @tasks = @tasks.joins(:service_channel => :users).where(users: { id: self.user_ids })
    end
    @tasks
  end

  def chat_records(type = self.kind)
    @chat_records ||= ChatRecord.joins(:service_channel, :media_channel).where('service_channels.company_id' => self.company_id)

    if self.starts_at && self.ends_at
      if type == 'comparison'
        @chat_records = @chat_records.for_period_updated_at(self.starts_at, self.ends_at)
      else
        @chat_records = @chat_records.for_period(self.starts_at, self.ends_at)
      end
    end
  end

  def agent_call_logs(type = self.kind)
    @agent_call_logs ||= self.company.agent_call_logs

    if self.starts_at && self.ends_at
      if type == 'comparison'
        @agent_call_logs = @agent_call_logs.for_period_updated_at(self.starts_at, self.ends_at)
      else
        @agent_call_logs = @agent_call_logs.for_period(self.starts_at, self.ends_at)
      end
    end
  end

  def chatbot_stats(type = self.kind)
    @chatbot_stats ||= self.company.chatbot_stats

    if self.starts_at && self.ends_at
      if type == 'comparison'
        @chatbot_stats = @chatbot_stats.for_period_updated_at(self.starts_at, self.ends_at)
      else
        @chatbot_stats = @chatbot_stats.for_period(self.starts_at, self.ends_at)
      end
    end
  end

  def orders(type = self.kind)
    @orders ||= self.company.orders

    if self.starts_at && self.ends_at
      if type == 'comparison'
        @orders = @orders.for_period_updated_at(self.starts_at, self.ends_at)
      else
        @orders = @orders.for_period(self.starts_at, self.ends_at)
      end
    end
  end

  def is_for_dashboard! # (CON-126) Dirty fix to differentiate between a generated report (which should show solved tasks as well) & dashboard
    @is_for_dashboard = true
  end

  def is_for_dashboard?
    @is_for_dashboard
  end

  def messages
    @messages ||= ::Message.where(task_id: self.tasks.pluck(:id))
  end

  # def get_data
  def get_data(*args)

    if self.starts_at
      self.starts_at = self.starts_at.beginning_of_day
    end
    if self.ends_at
      self.ends_at = self.ends_at.end_of_day
    end

    if args[0].present?
      get_summary_data(args[0]).merge(get_comparison_data)
    else
      get_summary_data.merge(get_comparison_data)
    end

  end


  def count(tasks, filter_method)
    tasks.select(&filter_method).uniq.count
  end

  def get_avg_processing_time(tasks_for_channel)
    ready_tasks = tasks_for_channel.select(&:ready?).uniq
    return 0 if ready_tasks.empty?
    ready_tasks.map(&:minutes_spent).reduce(&:+).to_i / ready_tasks.count
  end

  # def get_summary_data(for_widgets=[])
  def get_summary_data(*args)
    @data = {}
    @data[:total_tasks_count] = self.tasks.uniq.count
    # @data[:total_unsolved_tasks_count] = self.tasks.unsolved_new.uniq.count
    if args[0].present?
      # @data[:total_unsolved_tasks_count] = self.tasks.joins(:messages).where('messages.inbound'=> true).uniq.count
        @data[:total_unsolved_tasks_count] = self.tasks.unsolved_new.uniq.count
      # @data[:total_unsolved_tasks_count] = self.tasks.in_bound_email_sms_channel(args[0].company.agents.ids).unsolved_new.uniq.count
    else
      @data[:total_unsolved_tasks_count] = self.tasks.unsolved_new.uniq.count
    end

    @data[:tasks_count] = { }
    total_count_tasks_with_red_alert = 0
    total_count_tasks_with_yellow_alert = 0
    total_count_tasks_with_no_alert = 0
    total_avg_processing_time = 0
    total_avg_waiting_period = 0
    channels_with_tasks_count = 0
    %i[email_channel web_form_channel internal_channel].each do |channel|
      tasks_for_channel = self.tasks.includes(media_channel: [:weekly_schedule]).__send__(channel.to_s)
      tasks_for_channel_count = tasks_for_channel.uniq.count
      channels_with_tasks_count = channels_with_tasks_count + 1 if tasks_for_channel_count > 0

      avg_processing_time = get_avg_processing_time(tasks_for_channel)
      total_avg_processing_time = total_avg_processing_time + avg_processing_time

      tasks_for_channel.each do |task|
         next if task.ready? && !task.inbound?
        if task.minutes_till_red_alert <= 0
          total_count_tasks_with_red_alert += 1
        elsif task.minutes_till_yellow_alert <= 0
          total_count_tasks_with_yellow_alert += 1
        else
          total_count_tasks_with_no_alert += 1
        end
      end

      counters = {
        total:   tasks_for_channel_count,
        new:     count(tasks_for_channel, :new?),
        open:    count(tasks_for_channel, :open?),
        waiting: count(tasks_for_channel, :waiting?),
        ready:   count(tasks_for_channel, :ready?),
        avg_processing_time: ::Helpers::TimeFormat.format_minutes(avg_processing_time)
      }
      # waiting period
      first_replies = tasks_for_channel.joins(:messages).where('messages.number' => 2)
                                       .pluck(:id, 'messages.created_at as msg_created_at', :created_at)

      avg_waiting_period = first_replies.count > 0 ?
                             (first_replies.map { |x| (x[1] - x[2]) / 60 }.reduce(&:+).to_i / first_replies.count)
                             : 0
      total_avg_waiting_period = total_avg_waiting_period + avg_waiting_period
      counters[:avg_waiting_period] = first_replies.count > 0 ?
        ::Helpers::TimeFormat.format_minutes(avg_waiting_period)
        : '0m'
      counters[:unsolved] = counters[:new] + counters[:open] + counters[:waiting]
      @data[:tasks_count][channel] = counters
    end

    # different stats for call channel
    tasks_for_channel = self.tasks.includes(media_channel: [:weekly_schedule]).call_channel
    tasks_for_channel_count = tasks_for_channel.uniq.count
    channels_with_tasks_count = channels_with_tasks_count + 1 if tasks_for_channel_count > 0
    avg_processing_time = tasks_for_channel_count > 0 ?
                            (tasks_for_channel.select(&:ready?).uniq.map(&:minutes_spent).reduce(&:+).to_i / tasks_for_channel_count) : 0
    total_avg_processing_time = total_avg_processing_time + avg_processing_time
    counters = {
      total:    tasks_for_channel_count,
      positive: count(tasks_for_channel, :positive?),
      negative: count(tasks_for_channel, :negative?),
      neutral:  count(tasks_for_channel, :neutral?),
      waiting:  count(tasks_for_channel, :waiting?),
      ready:    count(tasks_for_channel, :ready?),
      avg_processing_time: ::Helpers::TimeFormat.format_minutes(avg_processing_time)
    }
    time_diff = tasks_for_channel.where(state: :ready).pluck(:created_at, :updated_at)

    tasks_for_channel.each do |task|
      next if task.ready? && !task.inbound?
      next if task.ready? && !task.inbound?
      if task.minutes_till_red_alert <= 0
        total_count_tasks_with_red_alert += 1
      elsif task.minutes_till_yellow_alert <= 0
        total_count_tasks_with_yellow_alert += 1
      else
        total_count_tasks_with_no_alert += 1
      end
    end

    avg_waiting_period = time_diff.length > 0 ?
                           ((time_diff.map { |x| (x[1] - x[0]) / 60 }.reduce(&:+).to_i / time_diff.length).to_i) : 0
    total_avg_waiting_period = total_avg_waiting_period + avg_waiting_period
    counters[:avg_waiting_period] = time_diff.length > 0 ?
      ::Helpers::TimeFormat.format_minutes(avg_waiting_period) : '0m'
    counters[:unsolved] = tasks_for_channel.select(&:new?).uniq.count + counters[:waiting]
    @data[:tasks_count][:call_channel] = counters


    # chat
    tasks_for_channel = self.tasks.includes(media_channel: [:weekly_schedule]).chat_channel
    tasks_for_channel_count = tasks_for_channel.uniq.count

    calls_records = self.agent_call_logs.for_reports
    calls_records_answered = calls_records.answered
    calls_records_unanswered = calls_records.unanswered
    calls_records_answered_count = calls_records_answered.count
    calls_records_unanswered_count = calls_records_unanswered.count
    calls_records_total = calls_records_answered_count + calls_records_unanswered_count

    total_tickets = self.tasks.from_softfone
    sale_tickets = self.tasks.joins(:campaign_item)
    total_tickets_count = total_tickets.count
    sale_tickets_count = sale_tickets.count

    counters = {
      total: calls_records_total,
      total_calls: calls_records_total,
      answered_count: calls_records_answered_count,
      unanswered_count: calls_records_unanswered_count,
      tickets_counts: (total_tickets_count - sale_tickets_count),
      sales_counts: sale_tickets_count,
      free_agents: self.company.agents.free.count,
      busy_agents: self.company.agents.busy.count,
      average_call_wait_seconds: calls_records.average_call_wait_seconds,
      average_call_duration_seconds: calls_records.average_call_duration_seconds
    }

    @data[:tasks_count][:agent_calls] = counters


    chat_records_for_channel = self.chat_records
    chat_records_for_channel_count = chat_records_for_channel.count

    channels_with_tasks_count = channels_with_tasks_count + 1 if tasks_for_channel_count > 0 || chat_records_for_channel_count > 0
    avg_processing_time = chat_records_for_channel.where("chat_records.ended_at IS NOT NULL").average("extract(epoch from chat_records.ended_at) - extract(epoch from chat_records.answered_at)").to_i / 60
    total_avg_processing_time = total_avg_processing_time + avg_processing_time

    avg_waiting_period = chat_records_for_channel.where("chat_records.answered_at IS NOT NULL").average("extract(epoch from chat_records.answered_at) - extract(epoch from chat_records.created_at)").to_i
    total_avg_waiting_period = total_avg_waiting_period + (avg_waiting_period / 60)
    counters = {
      total: chat_records_for_channel_count,
      answered: chat_records_for_channel.where("answered_at IS NOT NULL").count,
      unanswered: chat_records_for_channel.where("answered_at IS NULL").count,
      positive: count(chat_records_for_channel, :positive?),
      negative: count(chat_records_for_channel, :negative?),
      neutral: count(chat_records_for_channel, :neutral?),
      tasks: tasks_for_channel_count,
      avg_waiting_period: avg_waiting_period.to_s + 's',
      avg_processing_time: ::Helpers::TimeFormat.format_minutes(avg_processing_time)
    }

    tasks_for_channel.each do |task|
      next if task.ready? && !task.inbound?
      if task.minutes_till_red_alert <= 0
        total_count_tasks_with_red_alert += 1
      elsif task.minutes_till_yellow_alert <= 0
        total_count_tasks_with_yellow_alert += 1
      else
        total_count_tasks_with_no_alert += 1
      end
    end

    @data[:tasks_count][:chat_channel] = counters
    @data[:total_tasks_count_for_pie] = self.tasks.uniq.count + chat_records_for_channel_count

    @data[:peak_times] = { }
    %i[email_channel web_form_channel call_channel chat_channel internal_channel].each do |channel|
      # NOTE: using PostgreSQL-specific SQL here
      data = self.messages.__send__(channel)
                          .select('EXTRACT(HOUR FROM messages.created_at) as hour', 'COUNT(*) as emails_count')
                          .group('hour')
                          .map { |m| [::Helpers::TimeFormat.get_hour_in_time_zone(m.hour.to_i), m.emails_count] }
                          .sort_by { |h| h.first }
      @data[:peak_times][channel] = data
    end


    @data[:peak_times][:agent_calls] = calls_records
                          .select('EXTRACT(HOUR FROM agent_call_logs.created_at) as hour', 'COUNT(*) as calls_count')
                          .group('hour')
                          .map { |m| [::Helpers::TimeFormat.get_hour_in_time_zone(m.hour.to_i), m.calls_count] }
                          .sort_by { |h| h.first }

    # sms
    tasks_for_channel = self.tasks.sms_channel
    #  counters = {
    #   sended: tasks_for_channel.count,
    #   received: tasks_for_channel.where(hidden: nil).count,
    #   new:     tasks_for_channel.where(state: 'new', hidden: nil).count,
    #   open:    tasks_for_channel.where(state: 'open').count,
    #   waiting: tasks_for_channel.where(state: 'waiting').count,
    # }
    tasks_count = tasks_for_channel.count
    group_sms_tasks = tasks_for_channel.where(group_sms: true)
    group_sms_tasks_count = group_sms_tasks.count
    tasks_replyes_count = group_sms_tasks.joins(:messages).where('messages.inbound'=> true).uniq.count
    hitrate = tasks_replyes_count > 0 && group_sms_tasks_count > 0 ? (tasks_replyes_count.to_f / group_sms_tasks_count * 100).round(0) : 0
    avg_processing_time = get_avg_processing_time(tasks_for_channel)
    if args[0].present?
      tasks_received = tasks_for_channel.where(hidden: nil).joins(:messages).where('messages.inbound'=> true).uniq.count
      counters = {
        sended: tasks_count,
        received: tasks_received,
        new:     tasks_for_channel.where(state: 'new', hidden: nil).where.not(send_by_user_id: args[0].company.agents.ids).count,
        open:    tasks_for_channel.where(state: 'open').count,
        waiting: tasks_for_channel.where(state: 'waiting').count,
        hitrate: hitrate,
      }
    else
      tasks_received = tasks_for_channel.where(hidden: nil).count
      counters = {
        sended: tasks_count,
        received: tasks_received,
        new:     tasks_for_channel.where(state: 'new', hidden: nil).count,
        open:    tasks_for_channel.where(state: 'open').count,
        waiting: tasks_for_channel.where(state: 'waiting').count,
        hitrate: hitrate,
      }
    end

    time_diff = tasks_for_channel.where(state: :ready).pluck(:created_at, :updated_at)
    avg_waiting_period = time_diff.length > 0 ?
                             ((time_diff.map { |x| (x[1] - x[0]) / 60 }.reduce(&:+).to_i / time_diff.length).to_i) : 0
    counters[:avg_waiting_period] = time_diff.length > 0 ?
                                        ::Helpers::TimeFormat.format_minutes(avg_waiting_period) : '0m'

    counters[:avg_processing_time] = ::Helpers::TimeFormat.format_minutes(avg_processing_time)
    @data[:tasks_count][:sms_channel] = counters
#        sended: tasks_for_channel.where(send_by_user_id: 3).count,
# 282:      received: tasks_for_channel.where.not(send_by_user_id: 3).count,


    tasks_for_channel.each do |task|
      next if task.ready? && !task.inbound?
      if task.minutes_till_red_alert <= 0
        total_count_tasks_with_red_alert += 1
      elsif task.minutes_till_yellow_alert <= 0
        total_count_tasks_with_yellow_alert += 1
      else
        total_count_tasks_with_no_alert += 1
      end
    end

    # avoid self created new
    # self_created_new_for_task = self.tasks.where(send_by_user_id: args[0].company.agents.ids, state: 'new').select('id')
    # # (CON-126) Dirty fix to differentiate between a generated report (which should show solved tasks as well) & dashboard
    # if self_created_new_for_task.present?
    #   included_tasks = self.tasks.where.not(id: self_created_new_for_task)
    # else
      included_tasks = self.tasks
    # end
    # "Tasks by service channel" horizontal bar chart
    raw_tasks_by_service_channel =  included_tasks.joins(:service_channel).select('COUNT(DISTINCT tasks.id) as tasks_count', 'service_channels.id', 'tasks.state','service_channels.name'
    ).group('service_channels.id', 'tasks.state')
    @data[:service_channel_data] = horizontal_bar_data(raw_tasks_by_service_channel)

    @data[:service_channel_ticks] = raw_tasks_by_service_channel.to_a.uniq{|r| r.id}.sort_by{ |x| [x.name, x.id] }.reverse.each_with_index.map{|s,i| [i, s.name]}

    #chatbot
    @data[:chatbot_stat] = {}
    chatbot_stats = self.chatbot_stats

    orders_count = self.orders.count
    tickets_count = self.tasks.where("is_from_chatbot_custom_action_button = true").count

    answered_chats_count = chatbot_stats.where("answered_messages > 0" ).count
    successful_chats_count = chatbot_stats.where(switched_to_agent: false).where("answered_messages > 0" ).count
    unsuccessful_chats_count = chatbot_stats.where(switched_to_agent: true).count
    total_chats_count = successful_chats_count + unsuccessful_chats_count

    answered_msgs_count = chatbot_stats.sum(:answered_messages)
    unanswered_msgs_count = unsuccessful_chats_count
    total_msgs_count = answered_msgs_count + unanswered_msgs_count

    counters = {
      orders: orders_count,
      tickets: tickets_count,
      successful_chats: successful_chats_count,
      unsuccessful_chats: unsuccessful_chats_count,
      total_chats: total_chats_count,
      answered_msgs: answered_msgs_count,
      unanswered_msgs: unanswered_msgs_count,
      total_msgs: total_msgs_count
    }
    @data[:chatbot_stat] = counters
    @data[:chatbot_stat][:average_dealing_time] = answered_chats_count > 0 ? ::Helpers::TimeFormat.format_minutes((chatbot_stats.sum(:dealing_time).to_i/answered_chats_count)/60) : "0m"

    # "Tasks by location" horizontal bar chart
    raw_tasks_by_location = included_tasks.joins(:service_channel => :locations)
                                  .select(
                                    'COUNT(DISTINCT tasks.id) as tasks_count', 'locations.id',
                                    'locations.name', 'tasks.state'
                                  )
                                  .group('locations.id', 'tasks.state')

    @data[:location_data] = horizontal_bar_data(raw_tasks_by_location)
    @data[:location_ticks] = raw_tasks_by_location.to_a.uniq{|r| r.id}.sort_by{ |x| [x.name, x.id] }.reverse.each_with_index.map{|s,i| [i, s.name]}
    @data[:total_avg_processing_time] = channels_with_tasks_count > 0 ?
                                          ::Helpers::TimeFormat.format_minutes(total_avg_processing_time / channels_with_tasks_count) :
                                          0
    @data[:total_avg_waiting_period] = channels_with_tasks_count > 0 ?
                                         ::Helpers::TimeFormat.format_minutes(total_avg_waiting_period / channels_with_tasks_count) :
                                         0

    @data[:sla] = {}
    total_not_ready_tasks_count = total_count_tasks_with_red_alert + total_count_tasks_with_yellow_alert + total_count_tasks_with_no_alert
    @data[:total_not_ready_tasks_count] = total_not_ready_tasks_count
    @data[:sla][:total_count_tasks_with_red_alert] = total_count_tasks_with_red_alert
    @data[:sla][:total_count_tasks_with_yellow_alert] = total_count_tasks_with_yellow_alert
    @data[:sla][:total_count_tasks_with_no_alert] = total_count_tasks_with_no_alert
    @data
  end

  def horizontal_bar_data(raw_data)
    data_set = {}
    main_states = Task.main_states
    main_states.each{|s| data_set[s.to_s] = {}}
    raw_data.each do |t|
      data_set[t.state][t.id] = t if data_set[t.state]
    end
    ready_data = []
    groupers = raw_data.sort_by { |x| [x.name, x.id] }.reverse.map(&:id).uniq
#    groupers = raw_data.map(&:id).uniq.sort
    main_states.each do |m|
      data = {label: m.to_s.humanize, data: [] }
      groupers.each_with_index do |s_id, i|
        t_data = data_set[m.to_s][s_id]
        data[:data] << (t_data ? [t_data.tasks_count, i] : [0, i])
      end
      ready_data << data
    end
    ready_data
  end


  def get_agent_ticks(data)
    @agent_ticks ||= ::Hash[*self.users.map { |u| [u.id, u.full_name] }.flatten]
    data.map { |t| [ t.position, @agent_ticks[t.id] ] }
  end

  def add_default_values(data, users, data_key)
    i = data.length
    users.map do |user|
      data.find { |d| d.id == user.id } || ::OpenStruct.new(:position => (i+=1), :id => user.id, data_key => 0)
    end
  end

  def get_comparison_data
    @data = {}
    # NOTE: using PostgreSQL-specific SQL
    # tasks
    tasks_by_user = self.tasks('comparison').ready.where(assigned_to_user_id: self.user_ids)
                              .select(
                                      'COUNT(DISTINCT tasks.id) as tasks_count', 'assigned_to_user_id as id',
                                      'ROW_NUMBER() OVER(ORDER BY assigned_to_user_id) as position'
                              )
                              .group('assigned_to_user_id')
    tasks_by_user = add_default_values(tasks_by_user, self.users, :tasks_count)
    @data[:tasks_data] = tasks_by_user.map { |t| [t.position, t.tasks_count] }
    @data[:tasks_ticks] = get_agent_ticks(tasks_by_user)
    # turnaround
    tasks_turnaround = self.tasks('comparison').select(
                                    'AVG(minutes_spent) as avg_turnaround ', 'assigned_to_user_id as id',
                                    'ROW_NUMBER() OVER(ORDER BY assigned_to_user_id) as position'
                                  )
                                  .where('minutes_spent > 0')
                                  .where(assigned_to_user_id: self.user_ids)
                                  .group(:assigned_to_user_id)
    tasks_turnaround = add_default_values(tasks_turnaround, self.users, :avg_turnaround)
    @data[:tasks_turnaround_data] = tasks_turnaround.map { |t| [t.position, t.avg_turnaround.to_i] }
    @data[:tasks_turnaround_ticks] = get_agent_ticks(tasks_turnaround)
    # pauses
    if self.starts_at and self.ends_at
      timelogs = ::Timelog.for_period(self.starts_at,self.ends_at)
    else
      timelogs = ::Timelog
    end

    pauses = timelogs.joins(:user).select(
                                           'SUM(minutes_paused) * 100.0 / SUM(minutes_worked) as pauses_percentage',
                                           'user_id as id',
                                           'ROW_NUMBER() OVER(ORDER BY user_id) as position'
                                   )
                                   .where(user_id: self.user_ids)
                                   .where('minutes_worked > 0')
                                   .group(:user_id)

    pauses = add_default_values(pauses, self.users, :pauses_percentage)

    @data[:pauses_data] = pauses.map { |t| [t.position, t.pauses_percentage.to_f.round(2) ] }
    @data[:pauses_ticks] = get_agent_ticks(pauses)

    # solutions %
    solutions_perc = self.tasks('comparison').select(
                                 "SUM(CASE WHEN state='ready' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as solutions_percentage",
                                 'assigned_to_user_id as id',
                                 'ROW_NUMBER() OVER(ORDER BY assigned_to_user_id) as position'
                                )
                                .where('assigned_to_user_id IS NOT NULL').where(assigned_to_user_id: self.user_ids)
                                .group(:assigned_to_user_id)
    solutions_perc = add_default_values(solutions_perc, self.users, :solutions_percentage)
    @data[:solutions_perc_data] = solutions_perc.map { |t| [t.position, t.solutions_percentage.to_f.round(2) ] }
    @data[:solutions_perc_ticks] = get_agent_ticks(solutions_perc)
    @data
  end


  def format_duration(duration)
    days = duration / 1440
    duration = duration % 1440
    hours = duration /  60
    hours = duration % 60
    minutes = duration
  end
end
