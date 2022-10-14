class RemoveDefaultTextFromChatSettingsInitialMsg < ActiveRecord::Migration
  def change
    change_column :chat_settings, :initial_msg, :string, default: ''
  end
end
