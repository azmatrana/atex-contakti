class FetchEmailsWorker
  include Sidekiq::Worker

  def perform
    ::Company.where.not(inactive: true).find_each do |company|
      company.service_channels.each do |service_channel|
        [service_channel.email_media_channel, service_channel.web_form_media_channel].each do |channel|
          next if !channel || !channel.active? || !channel.imap_settings
          ::FetchEmailsFromChannelWorker.perform_async(channel.id)
        end
      end
    end

    ServiceChannel.joins(:user).find_each do |service_channel|
      [service_channel.email_media_channel, service_channel.web_form_media_channel].each do |channel|
        next if !channel || !channel.active? || !channel.imap_settings
        ::FetchEmailsFromChannelWorker.perform_async(channel.id)
      end
    end
  end

end
