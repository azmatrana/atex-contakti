class AddChatSettingsIdToMediaChannel < ActiveRecord::Migration
  def change
    add_column :media_channels, :chat_settings_id, :integer
  end
end
