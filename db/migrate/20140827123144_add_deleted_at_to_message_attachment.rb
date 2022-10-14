class AddDeletedAtToMessageAttachment < ActiveRecord::Migration
  def change
    add_column :message_attachments, :deleted_at, :datetime
    add_index :message_attachments, :deleted_at
  end
end
