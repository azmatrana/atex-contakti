class PopulateMissingMediaChannelIds < ActiveRecord::Migration

  def up
    ::Task.unscoped.where(media_channel_id: nil).find_each do |task|
      if task.service_channel && (email_media_channel = task.service_channel.email_media_channel)
        task.update_attribute(:media_channel_id, email_media_channel.id)
      end
    end
  end

  def down
    # nothing to do here
  end

end
