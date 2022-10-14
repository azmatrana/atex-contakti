class CreateNoteAttachments < ActiveRecord::Migration
  def change
    create_table :note_attachments do |t|
      t.column :note_id, :integer, null: false
      t.column :file, :oid, null: false
      t.string :file_name, null: false
      t.integer :file_size, null: false
      t.string :content_type, null: false
      t.timestamps
    end
  end
end
