class AddCustomizationFieldsToChatSettings < ActiveRecord::Migration
  def change
     add_column :chat_settings, :color, :string, :default => '#0dc0c0'
     add_column :chat_settings, :welcome_message, :string, :default => 'How can I help?'
  end
end
