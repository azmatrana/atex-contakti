class FetchEmailsFromChannelWorker
  include ::Sidekiq::Worker
  sidekiq_options unique: true,
                  unique_args: ->(args) { [args.first] }

  def perform(media_channel_id)
#    if Rails.env.development?
#      return
#    end
    channel = ::MediaChannel.find_by_id(media_channel_id)
    return if channel.nil?
    return unless channel.imap_settings.try(:all_required_data_fills?)
    begin
      logger.info"CALLING ImapService.fetch_emails(channel) "
      ::ImapService.fetch_emails(channel)
    rescue => e
      logger.info "Exception on fetching emails for channel #{channel.service_channel.name}: #{e.message}\n#{e.backtrace.join("\n")}"
    end
  end
end
