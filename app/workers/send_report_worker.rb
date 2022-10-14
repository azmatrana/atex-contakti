class SendReportWorker
  include Sidekiq::Worker

  def perform(report_id, options)
    ::ReportMailer.report(report_id, options).deliver
  end

end
