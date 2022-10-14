class TaskDecorator < ApplicationDecorator
  decorates_association :messages

  # TODO: translation
  def format_time_spent(minutes_spent)
    if minutes_spent.to_f == Float::INFINITY
      '&infin;'
    elsif minutes_spent > 60
      hours = (minutes_spent / 60).floor
      minutes = minutes_spent - (hours * 60)
      "#{hours}h #{'%g' % minutes}min"
    else
      "#{'%g' % minutes_spent}min"
    end
  end

  def time_spent
    minutes_spent = object.open? ? object.total_minutes_spent : object.minutes_spent
    format_time_spent(minutes_spent)
  end

  def format_time_till_red_alert
    minutes_till_alert = object.minutes_till_red_alert
    "#{'+' if minutes_till_alert < 0}#{format_time_spent(minutes_till_alert.abs)}"
  end

  def format_minutes_till_red_alert
    object.minutes_till_red_alert
  end

  def get_clock_class
    case
    when object.minutes_till_red_alert < 0 then 'status-urgent'
    when object.minutes_till_yellow_alert < 0 then 'status-warning'
    else 'status-ok'
    end
  end

  def last_message_at
    object.messages.to_a.sort_by(&:created_at).last.try(:created_at)
  end

  def last_message_is_sms
    object.messages.to_a.sort_by(&:created_at).last.try(:sms)
  end

  def latest_message
    object.messages.select{|m| m.sms == false}.to_a.sort_by(&:created_at).last
  end

  def caller_name
    object.data['caller_name']
  end

  def call_counter
    object.data['missing_calls_counter']
  end

  def callback_task_mark_as_done_on_call
    object.media_channel.mark_done_on_call_action
  end
end
