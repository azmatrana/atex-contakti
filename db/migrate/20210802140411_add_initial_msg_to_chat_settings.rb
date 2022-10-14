class AddInitialMsgToChatSettings < ActiveRecord::Migration
  def change
    add_column :chat_settings, :initial_msg, :string, default: 'Let me see if any agent is online.'
  end
end
