class AddBelongsToSipSettingsToMediaChannels < ActiveRecord::Migration
  def change
    add_reference :media_channels, :sip_settings, index: true
  end
end
