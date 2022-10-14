class AddInternalMediaChannel < ActiveRecord::Migration
  def change
    ServiceChannel.all.each do |sc|
      next if sc.internal_media_channel.present?
      mc = sc.build_internal_media_channel
      mc.save rescue nil
    end
    User.all.each do |u|
      next if u.media_channel_types.include?('internal')
      u.media_channel_types << "internal"
      u.media_channel_types = u.media_channel_types.uniq
      u.save
    end
  end
end
