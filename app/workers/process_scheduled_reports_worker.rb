class ProcessScheduledReportsWorker
  include Sidekiq::Worker
  sidekiq_options unique: true, retry: false

  def perform
    ::Report.scheduled.each do |report|
      offset = case report.scheduled
               when 'daily'   then 1.day
               when 'weekly'  then 1.week
               when 'monthly' then 1.month
               end
      time_now = ::Time.current

      if report.schedule_start_sent_already
        if !report.last_sent_at || report.last_sent_at < (time_now - offset)
          send_message(report, time_now, offset)
        end
      else
        if !report.start_sending_at || report.start_sending_at < time_now
          send_message(report, time_now, offset)
          report.update_attribute(:schedule_start_sent_already, true)
        end
      end
    end
  end

  def send_message(report_object, time_now, offset)
    start_date = report_object.last_sent_at || time_now - offset
    ::ReportMailer.report(report_object.id, start_date: start_date, end_date: time_now).deliver
    report_object.update_attribute(:last_sent_at, time_now)
  end

end
