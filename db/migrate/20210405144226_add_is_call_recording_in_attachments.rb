class AddIsCallRecordingInAttachments < ActiveRecord::Migration
  def change
    add_column :message_attachments, :is_call_recording, :boolean, default: false
  end
end
