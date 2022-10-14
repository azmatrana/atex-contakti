class AddEnableBotChatInServiceChannel < ActiveRecord::Migration
  def change
    add_column :chat_settings, :enable_chatbot, :boolean, default: false
  end
end
