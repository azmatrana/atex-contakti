class UpdateIndexMessagesOnTaskIdAndMessageUid < ActiveRecord::Migration
  def change
    remove_index :messages, name: 'index_messages_on_task_id_and_message_uid'
    add_index(:messages, [:task_id, :message_uid], unique: true)
  end
end
