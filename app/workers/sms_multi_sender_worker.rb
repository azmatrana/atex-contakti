class SmsMultiSenderWorker
  include ::Sidekiq::Worker

  def perform(phone_numbers, message, options = {})
    service_channel = ServiceChannel.find options['service_channel_id']
    sms_media_channel = service_channel.sms_media_channel
    from = service_channel.sms_media_channel.try :sms_sender
    phone_numbers.each do |number|
      SmsSenderWorker.perform_async(
        from, number, message, service_channel.company_id
      )
      sms_media_channel.add_hidden_task(from, number, message) if options['create_tasks']
    end
  end
end
