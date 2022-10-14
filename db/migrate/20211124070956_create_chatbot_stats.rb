class CreateChatbotStats < ActiveRecord::Migration
  def change
    create_table :chatbot_stats do |t|
      t.integer :answered_messages, default: 0
      t.boolean :switched_to_agent, default: false
      t.string :chat_channel_id, null: false
      t.references :company
      t.timestamps
    end
  end
end