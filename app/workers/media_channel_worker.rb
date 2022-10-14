require_dependency 'media_channel_service'
class MediaChannelWorker
  include ::Sidekiq::Worker
  sidekiq_options unique: true

  def perform(media_channel_id)
    ::MediaChannelService.new(media_channel_id).check_active_state
  end
end