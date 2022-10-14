class CreateChatSettings < ActiveRecord::Migration
  def change
    create_table :chat_settings do |t|
      t.text :whitelisted_referers

      t.timestamps
    end
  end
end
