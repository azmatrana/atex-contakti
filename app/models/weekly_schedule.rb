# == Schema Information
#
# Table name: weekly_schedules
#
#  id               :integer          not null, primary key
#  schedulable_id   :integer
#  schedulable_type :string(255)
#  open_full_time   :boolean
#  created_at       :datetime
#  updated_at       :datetime
#

class WeeklySchedule < ActiveRecord::Base
  class NoBusinessTimeException < StandardError
  end

  belongs_to :schedulable, polymorphic: true
  has_many :schedule_entries

  accepts_nested_attributes_for :schedule_entries, allow_destroy: true

  after_initialize do
    self.open_full_time = true if open_full_time.nil?
  end

  def weekly_open_hours
    schedule_entries.for_weekdays
  end
  #Get open hours for week, adding empty entries for days with no entries
  def weekly_open_hours_with_empty
    entries = weekly_open_hours
    entries = [] if entries.empty?
    (1..7).each do |n|
      entries << ScheduleEntry.new(weekday: n) unless entries.find{|e| e.weekday == n}
    end
    entries
  end
  def weekly_open_hours_with_fixed_entries
    entries = weekly_open_hours
  end

  def entry_for_date(date)
    candidates = schedule_entries.to_a.select { |e| e.start_time_for_week(date).to_date == date.to_date }
    fixed_date = candidates.find_index { |e| e.fixed_date.present? }

    return candidates[fixed_date] if fixed_date.present?

    candidates.first
  end

  def next_business_day(date, options = {})
    entries = []

    schedule_entries.each do |e|
      next_start = e.next_start_after date.end_of_day
      entries << [next_start, e] if next_start.present?
    end

    entries.sort_by! { |e| e[0] }

    if entries.empty?
      raise NoBusinessTimeException, 'No upcoming business days in schedule after date'
    end

    start_date, entry = entries.first

    if options[:keep_time]
      start_date.midnight + date.seconds_since_midnight.seconds
    else
      start_date
    end
  end

  def has_business_time? # Checks whether this schedule has any business time in the future
    return true if open_full_time?

    has_time = false

    schedule_entries.each do |e|
      if e.has_duration? and (e.fixed_date.blank? or e.start_time_for_week >= DateTime.current)
        has_time = true
        break
      end
    end

    has_time
  end

  def date_after_working_time(working_time = { days: 0, hours: 0 }, date = DateTime.current, media_channel = "")
    unless has_business_time?
      raise NoBusinessTimeException, 'No upcoming business time in schedule'
    end
    logger.info "======working_time======#{working_time.inspect}===#{media_channel}==="
    days_left = working_time[:days] || 0
    hours_left = working_time[:hours] || 0
    logger.info "====days_left=====#{days_left.inspect}=====hours_left====#{hours_left.to_f.inspect}==#{open_full_time?}="
    if open_full_time? || media_channel == "MediaChannel::Call"
      return date + days_left.days + hours_left.hours
    end

    while days_left > 0
      date_hours = entry_for_date date
      logger.info "==IN days_left=====#{date_hours.inspect}=========="

      if date_hours.present?
        if date_hours.includes_time? date
          # date is during business hours => subtract 1 day + roll forward to the next business day, 1 day at a time
          days_left -= 1
          date = next_business_day date, keep_time: true # This may not end up being during the business hours of the day
        elsif date_hours.starts_after_time? date
          # date is before business hours => subtract 1 day + roll forward to the start of the next business day
          days_left -= 1
          date = next_business_day date
        else # Ends before date
          # date is after business hours => roll forward to the start of the next business day
          date = next_business_day date
        end
        logger.info "=if =end days_left=====#{date}=========="
      else
        # no business hours on date, roll forward to the start of the next business day
        date = next_business_day date
        logger.info "=else =end days_left=====#{date}=========="

      end
    end

    while hours_left > 0
      date_hours = entry_for_date date
      logger.info "==IN hours_left=====#{date_hours.inspect}=========="

      if date_hours.present?
        if date_hours.includes_time? date
          # date is during business hours => subtract remaining business time of the day or until hours_left = 0
          logger.info "==IN include_time?=====#{date_hours.inspect}=========="
          business_hours_left = (date_hours.end_time.seconds_since_midnight - date.seconds_since_midnight).to_f / 3600
          logger.info "==IN business_hours_left=====#{business_hours_left.inspect}=========="
          delta = [business_hours_left, hours_left].min
          logger.info "==IN delta=====#{delta.inspect}=========="
          hours_left -= delta
          date += delta.hours
          logger.info "==left time and date=====#{hours_left.to_f.inspect}======#{date.inspect}===="
        elsif date_hours.starts_after_time? date
          # date is before business hours => roll forward to the start of the business day
          date = date.midnight + date_hours.start_time.seconds_since_midnight.seconds
          logger.info "==IN starts_after_time?=====#{date.inspect}=========="
        else # Ends before date
          # date is after business hours => roll forward to the start of the next business day
          date = next_business_day date
          logger.info "==else=====#{date.inspect}=========="
        end
        logger.info "=IF=end hours_left=====#{date}=====#{hours_left.to_f.inspect}====="
      else
        # no business hours on date, roll forward to the start of the next business day
        date = next_business_day date
        logger.info "=ELSE =end hours_left=====#{date}=========="
      end
    end
    logger.info "==final date=====#{date.inspect}=========="
    date
  end

  #Get total work time span between two time points(ActiveSupport::TimeWithZone) in minutes
  def total_work_time_between(from, to)
    if open_full_time?
      return ((to - from)/60).round
    end
    entries = weekly_open_hours
    fixed_entries = schedule_entries.fixed_date_entries_in(from.beginning_of_day, to.end_of_day)
    total = 0
    entries_hash = entries.inject({}) { |col, current| col[current.weekday] = current; col }
    dates = ((from.beginning_of_day.to_datetime)..(to.beginning_of_day.to_datetime)).to_a
    dates.each_with_index do |date, index|
      date = date.in_time_zone
      weekday = date.strftime("%u").to_i
      entry = fixed_entries.find{|entry| entry.fixed_date.to_date === date.to_date } || entries_hash[weekday]
      if entry
        start_time = Time.zone.parse(date.strftime("%F ")+entry.start_time.strftime("%H:%M")) if entry.start_time
        end_time = Time.zone.parse(date.strftime("%F ")+entry.end_time.strftime("%H:%M")) if entry.end_time
        from = from.in_time_zone
        to = to.in_time_zone
      end
      if !entry || !start_time || !end_time
        total += 0
      elsif dates.length == 1
        total += (to > end_time ? end_time : to)-(from < start_time ? start_time : from)
      elsif index == 0
        total += (from > end_time ? 0 : (from < start_time ? (end_time - start_time) : (end_time - from)))
      elsif index == dates.length - 1
        total += (to < start_time ? 0 : (to > end_time ? (end_time - start_time) : (to - start_time)))
      else
        total += end_time - start_time
      end
    end
    (total/60).round
  end

end
