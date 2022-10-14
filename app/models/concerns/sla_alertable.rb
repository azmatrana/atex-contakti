module SlaAlertable
  extend ActiveSupport::Concern

  included do
    validates :red_alert_days, :yellow_alert_days, numericality: { only_integer: true, allow_nil: true }
    validates :red_alert_hours, :yellow_alert_hours, numericality: { allow_nil: true, less_than: 99.991 }

    attr_writer :yellow_alert_minutes
    attr_writer :red_alert_minutes

    before_validation :parse_alert_minutes
  end

  def yellow_alert_minutes
    @yellow_alert_minutes.is_a?(String) ? @yellow_alert_minutes.to_i : @yellow_alert_minutes
  end

  def red_alert_minutes
    @red_alert_minutes.is_a?(String) ? @red_alert_minutes.to_i : @red_alert_minutes
  end

  def validate_alert_levels
    self.errors.add(:yellow_alert_hours, :required) unless self.yellow_alert_days || self.yellow_alert_hours || self.yellow_alert_minutes
    self.errors.add(:red_alert_hours, :required) unless self.red_alert_days || self.red_alert_hours || self.red_alert_minutes
    if red_alert_limit_in_hours < yellow_alert_limit_in_hours
      self.errors.add(:red_alert_hours, :inconsistent_data)
    end
  end

  def parse_alert_minutes
    if self.yellow_alert_minutes.present?
      self.yellow_alert_hours = (self.yellow_alert_hours || 0) + ((self.yellow_alert_minutes || 0) / 60.0)
      self.yellow_alert_minutes = nil
    end
    if self.red_alert_minutes.present?
      self.red_alert_hours = (self.red_alert_hours || 0) + ((self.red_alert_minutes || 0) / 60.0)
      self.red_alert_minutes = nil
    end
  end

  def red_alert_limit_in_hours
    24 * (self.red_alert_days || 0) + (self.red_alert_hours || 0) + ((self.red_alert_minutes || 0) / 60.0)
  end

  def yellow_alert_limit_in_hours
    24 * (self.yellow_alert_days || 0) + (self.yellow_alert_hours || 0) + ((self.yellow_alert_minutes || 0) / 60.0)
  end

  def has_yellow_alert?
    has_alert_of_level?('yellow')
  end

  def has_red_alert?
    has_alert_of_level?('red')
  end

  #If including class does not validate with #validate_alert_levels, give a way to check if alert is actually configured
  def has_alert_of_level?(level)
    self.__send__("#{level}_alert_days").present? || self.__send__("#{level}_alert_hours").present?
  end

end