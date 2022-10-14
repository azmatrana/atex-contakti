class ReportMailer < ActionMailer::Base
  default from: 'support@contakti.com'

  def report(report_id, options = {})
    # create a screenshot
    @report = ::Report.find report_id
    screenshot = ::ScreenshotGenerator.new.generate_report_screenshot(@report, options)
#    attachments.inline['report.png'] = ::File.read(screenshot)
    attachments['report.pdf'] = ::File.read(@report.pdf)

    mail to: @report.send_to_emails, subject: "#{@report.title}"
  end

end
