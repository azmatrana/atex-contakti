module Helpers
  module TimeFormat
    extend self

    def format_minutes(minutes)
      if minutes > 60
        hours = (minutes / 60).floor
        if hours > 24
          days = (hours / 24).floor
          hours = hours - days * 24
          minutes = minutes - (hours * 60) - (days * 60 * 24)
          "#{days}d #{hours}h #{minutes}m"
        else
          minutes = minutes - hours * 60
          "#{hours}h #{minutes}m"
        end
      else
        "#{minutes}m"
      end
    end

    def get_minutes_to(date)
      return 0 unless date
      ((::Time.current - date) / 60).floor
    end

    def get_hour_in_time_zone(hour)
      # TODO: what to do with 1/2 hour and 1/4 hour offsets
      timezone_offset_in_hours = ::Time.zone.utc_offset / 60 / 60
      (hour + timezone_offset_in_hours) % 24
    end

  end
end
