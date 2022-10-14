module ServiceChannelsHelper

  def format_hours(value)
    return nil unless value.present?
    '%g' % value.to_i
  end

  def sla_minutes(hours = 0, minutes)
    minutes ||= 0
    if hours.present?
      minutes += ((hours - hours.to_i )* 60)
    end
    minutes.round
  end

end
