class AddFileToChatSettings < ActiveRecord::Migration
  def change
    add_column :chat_settings, :file, :string, null: true
  end
end
