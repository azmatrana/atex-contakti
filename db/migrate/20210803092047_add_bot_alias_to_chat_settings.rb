class AddBotAliasToChatSettings < ActiveRecord::Migration
  def change
    add_column :chat_settings, :bot_alias, :string
  end
end
