class ChangeColumnTypeOfChatSettingsWelcomeMessage < ActiveRecord::Migration
  def change
    change_column :chat_settings, :welcome_message, :text
    change_column :chat_settings, :initial_msg, :text
  end
end
