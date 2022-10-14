class CreateChatRecords < ActiveRecord::Migration
  def change
    create_table :chat_records do |t|
      t.string :channel_id
      t.datetime :answered_at
      t.integer :answered_by_user_id
      t.integer :service_channel_id
      t.integer :media_channel_id
      t.datetime :ended_at
      t.boolean :user_quit
      t.string :result
      t.string :name
      t.string :email
      t.string :phone

      t.timestamps
    end
    add_index :chat_records, :channel_id
    add_index :chat_records, :answered_at
  end
end
