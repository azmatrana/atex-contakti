class AddCustomChatTitleToChatSettings < ActiveRecord::Migration
  def change
    add_column :chat_settings, :chat_title, :string, default: "Chat"
  end
end
