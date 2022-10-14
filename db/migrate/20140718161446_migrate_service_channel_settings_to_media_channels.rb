class MigrateServiceChannelSettingsToMediaChannels < ActiveRecord::Migration
  def up
    ::ServiceChannel.unscoped do
      ::ServiceChannel.find_each do |service_channel|
        media_channel = ::EmailMediaChannel.new(service_channel_id: service_channel.id)

        imap                           = service_channel.imap_settings
        media_channel.imap_settings_id = imap.id if imap

        smtp                           = service_channel.smtp_settings
        media_channel.smtp_settings_id = smtp.id if smtp

        media_channel.save! if imap || smtp
      end
    end
  end

  def down
    # nothing to do here
  end

end
