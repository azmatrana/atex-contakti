class AddTextColorToChatSettings < ActiveRecord::Migration
  def change
    add_column :chat_settings, :text_color, :string, default: '#ffffff'
  end
end
