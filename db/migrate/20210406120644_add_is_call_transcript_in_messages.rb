class AddIsCallTranscriptInMessages < ActiveRecord::Migration
  def change
    add_column :messages, :call_transcript, :text
    add_column :messages, :cdr_call_log_id, :integer
  end
end
