class SmsSenderWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  sidekiq_options :retry => 5

  sidekiq_retry_in do |count|
    [60 * 15, 60 * 60, 60 * 60 * 3][count]
  end

  def perform(from, to, text, company_id)
    # TODO From SMS is predefined
    logger.info 'SmsSenderWorker'
    logger.info from.inspect
    company = ::Company.find(company_id)
    sent_successfully = false
    if company.sms_provider == ::Company::SMS_PROVIDERS[0]
      labyrintti_from = from.present? ? from : '16100'
      if Rails.env.development?
        sent_successfully = true
        open_text(text, to)
      else
        res = ::Labyrintti::SMS.new.send_text(from: labyrintti_from, to: to, text: text)
        sent_successfully = true if res[:ok]
      end
    elsif company.sms_provider == ::Company::SMS_PROVIDERS[1]
      tavoittaja_from = from.present? ? from : 'contakti'

      logger.info tavoittaja_from
      if Rails.env.development?
        sent_successfully = true
        open_text(text, to)
      else
        res = ::Tavoittaja::Sms.new(tavoittaja_from, to, text).send
        sent_successfully = true if res.code == '200'
      end
    end
    logger.info res.inspect unless Rails.env.development?
    if sent_successfully
      total_sms_sent = (text.length/160.0).ceil
      ::Company::Stat.update_counters company.current_stat.id, sms_sent: total_sms_sent
    else
      logger.debug res.inspect
      raise '============ SMS Sending Issue  ============='
    end
  end

  private

  def open_text(content, number)
    tmp_dir = Dir.mktmpdir
    file_path = File.join(tmp_dir, "#{SecureRandom.uuid}.html")

    File.open(file_path, "w") do |file|
      template = ERB.new(<<-TEMPLATE)
        <html>
          <head><title>Text message to #{number}</title></head>
          <body>
            #{content}
          </body>
        </html>
      TEMPLATE
      file.write(template.result(binding))
    end

    Launchy.open(file_path)
  end
end
