module SlaAlerts
  extend ActiveSupport::Concern

  included do
    validates :red_alert_days, :yellow_alert_days, numericality: { only_integer: true, allow_nil: true }
    validates :red_alert_hours, :yellow_alert_hours, numericality: { allow_nil: true }
  end

  def validate_alert_levels
    self.errors.add(:yellow_alert_hours, :required) unless self.yellow_alert_days || self.yellow_alert_hours
    self.errors.add(:red_alert_hours, :required) unless self.red_alert_days || self.red_alert_hours
    if red_alert_limit_in_hours < yellow_alert_limit_in_hours
      self.errors.add(:red_alert_hours, :inconsistent_data)
    end
  end

  def red_alert_limit_in_hours
    24 * (self.red_alert_days || 0) + (self.red_alert_hours || 0)
  end

  def yellow_alert_limit_in_hours
    24 * (self.yellow_alert_days || 0) + (self.yellow_alert_hours || 0)
  end

  def has_yellow_alert?
    has_alert_of_level('yellow')
  end

  def has_red_alert?
    has_alert_of_level('red')
  end

  #If including class does not validate with #validate_alert_levels, give a way to check if alert is actually configured
  def has_alert_of_level?(level)
    self.__send__("#{level}_alert_days").present? || self.__send__("#{level}_alert_hours").present?
  end

end