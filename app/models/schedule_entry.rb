# == Schema Information
#
# Table name: schedule_entries
#
#  id                 :integer          not null, primary key
#  weekly_schedule_id :integer
#  start_time         :datetime
#  end_time           :datetime
#  weekday            :integer
#  fixed_date         :datetime
#  created_at         :datetime
#  updated_at         :datetime
#

class ScheduleEntry < ActiveRecord::Base
  extend SimpleCalendar

  belongs_to :weekly_schedule

  scope :for_weekdays, -> { where('weekday IS NOT NULL') }

  scope :fixed_date_entries_in, -> (from, to) {
    where("fixed_date >= ? AND fixed_date <= ?", from, to)
  }

  validates :start_time, presence: true
  validates :end_time, presence: true


  has_calendar attribute: :start_time_for_week

  #Need to get the start times for current week to place correctly on calendar
  def start_time_for_week(week_date = nil)
    if fixed_date.present?
      DateTime.new(fixed_date.year, fixed_date.month, fixed_date.day, start_time.hour, start_time.min)
    else
      today = week_date.present? ? week_date.to_datetime : DateTime.current
      start_time.present? ? DateTime.commercial(today.year, today.cweek, weekday, start_time.hour, start_time.min) : DateTime.commercial(today.year, today.cweek, weekday)
    end
  end

  def period_is_valid
    if start_time > end_time
      errors.add(:start_time, 'cannot be later than end time')
    end
  end

  def duration
    end_time.seconds_since_midnight - start_time.seconds_since_midnight
  end

  def has_duration?
    duration > 0
  end

  def has_future_duration?(date = nil)
    date ||= DateTime.current
    has_duration? and (weekday.present? or (fixed_date.present? and fixed_date >= date))
  end

  def includes_time?(date)
    date.seconds_since_midnight >= start_time.seconds_since_midnight and date.seconds_since_midnight < end_time.seconds_since_midnight
  end

  def starts_after_time?(date)
    date.seconds_since_midnight < start_time.seconds_since_midnight
  end

  def ends_before_time?(date)
    date.seconds_since_midnight > end_time.seconds_since_midnight
  end

  def next_start_after(date) # Soonest possible date & time when this entry could start after `date`
    start = nil
    date = date.to_datetime
    if fixed_date.present?
      start = fixed_date if fixed_date > date
    elsif weekday.present?
      start = start_time.present? ? DateTime.commercial(date.year, date.cweek, weekday, start_time.hour, start_time.min) : DateTime.commercial(date.year, date.cweek, weekday)
      start += 1.week if start <= date
    end

    start
  end
end
