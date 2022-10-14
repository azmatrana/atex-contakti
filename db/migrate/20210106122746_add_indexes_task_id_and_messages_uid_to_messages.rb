class AddIndexesTaskIdAndMessagesUidToMessages < ActiveRecord::Migration
  def change
    add_index(:messages, [:task_id, :message_uid])
  end
end
