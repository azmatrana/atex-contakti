# == Schema Information
#
# Table name: tasks
#
#  id                  :integer          not null, primary key
#  state               :string(100)      default(""), not null
#  service_channel_id  :integer
#  created_at          :datetime
#  updated_at          :datetime
#  uuid                :uuid
#  minutes_spent       :integer          default(0), not null
#  assigned_to_user_id :integer
#  last_opened_at      :datetime
#  opened_at           :datetime
#  turnaround_time     :integer          default(0), not null
#  media_channel_id    :integer
#  deleted_at          :datetime
#  assigned_at         :datetime
#  result              :string(20)       default(""), not null
#  data                :json             default({}), not null
#  created_by_user_id  :integer
#
# Indexes
#
#  index_tasks_on_deleted_at  (deleted_at)
#

class FullTaskSerializer < ActiveModel::Serializer
  attributes *(Task.attribute_names.map(&:to_sym) - [:media_channel_id]),
             :time_spent,
             :may_start?,
             :may_renew?,
             :may_restart?,
             :may_pause?,
             :may_close?,
             :may_lock?,
             :may_unlock?,
             :get_clock_class,
             :minutes_till_yellow_alert,
             :minutes_till_red_alert,
             :format_time_till_red_alert,
             :red_alert_or_ready_date,
             :is_not_call?,
             :media_channel,
             :priority,
             :skills_priority,
             :last_message_at,
             :last_message_is_sms,
             :latest_message,
             :caller_name,
             :call_counter,
             :note_body,
             :has_schedule?,
             :has_time_in_schedule?,
             :created_by_user_id,
             :flags,
             :skills,
             :generic_tags,
             :data,
             :service_channel_agent_ids,
             :skills_matched_service_channel_agents,
             :note_attachments,
             :follow_user_ids,
             :order_id,
             :callback_task_mark_as_done_on_call

  has_one :service_channel
  has_one :agent
  has_one :customer
  has_one :closed_by_user
  has_one :send_by_user
  has_many :messages, serializer: ExtendMessageSerializer
  has_one :draft

  def created_by_user_id
    object.created_by_user_id rescue nil
  end

  def flags
    object.flag_list
  end

  def skills
    object.skill_list
  end

  def generic_tags
    object.generic_tag_list
  end

  def media_channel
    case object.media_channel
    when ::MediaChannel::WebForm
      'web_form'
    when ::MediaChannel::Internal
      'internal'
    when ::MediaChannel::Call
      'call'
    when ::MediaChannel::Chat
      'chat'
    when ::MediaChannel::Sms
      'sms'
    else
      'email'
    end
  end

  def note_body
    object.note.try(:body)
  end

  def note_attachments
    (object.note.try(:attachments) || []).map do |att|
      { id: att.id, file_name: att.file_name, note_id: att.note_id }
    end
  end

  # TODO Rewrite to aliases. but first need to write specs

  def include_caller_name?
    object.media_channel.is_a?(::MediaChannel::Call)
  end

  def include_call_counter?
    object.media_channel.is_a?(::MediaChannel::Call)
  end

  def include_callback_task_mark_as_done_on_call?
    object.media_channel.is_a?(::MediaChannel::Call)
  end

  def minutes_till_red_alert
    minutes = object.minutes_till_red_alert
    minutes.to_f == Float::INFINITY ? '&infin;' : minutes
  end

  def minutes_till_yellow_alert
    minutes = object.minutes_till_yellow_alert
    minutes.to_f == Float::INFINITY ? '&infin;' : minutes
  end

  def has_schedule?
    object.weekly_schedule.present?
  end

  def has_time_in_schedule?
    object.weekly_schedule.present? and object.weekly_schedule.has_business_time?
  end

  def priority
    priority = skills_priority.map do |p|
      p[:priority]
    end.max || 0
  end

  def skills_priority
    object.skills_priority
  end

  def service_channel_agent_ids
    object.service_channel.locations.collect(&:users).collect(&:ids).flatten
  rescue
    []
  end

  def skills_matched_service_channel_agents
    object.skills_matched_service_channel_agents(object.skills)
  end

  def follow_user_ids
    object.follows.map(&:user_id)
  end

  def order_id
    object.order.try(:id)
  end
end
