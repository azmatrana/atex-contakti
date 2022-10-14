module WeeklySchedulable
  extend ActiveSupport::Concern
  included do
    has_one :weekly_schedule, as: :schedulable, dependent: :destroy
    accepts_nested_attributes_for :weekly_schedule
  end

  def weekly_open_hours
    weekly_schedule.present? ? weekly_schedule.send(:weekly_open_hours) : []
  end

  def weekly_open_hours_with_empty
    weekly_schedule.present? ? weekly_schedule.send(:weekly_open_hours_with_empty) : []
  end
end
