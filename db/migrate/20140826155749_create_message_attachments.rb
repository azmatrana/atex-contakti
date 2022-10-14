class CreateMessageAttachments < ActiveRecord::Migration
  def change
    create_table :message_attachments do |t|
      t.column :message_id, :uuid, null: false
      t.column :file, :oid, null: false
      t.string :file_name, null: false
      t.integer :file_size, null: false
      t.string :content_type, null: false
      t.timestamps
    end
  end
end
