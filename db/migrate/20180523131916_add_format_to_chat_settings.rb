class AddFormatToChatSettings < ActiveRecord::Migration
  def change
    add_column :chat_settings, :format, :integer, default: 0
  end
end
