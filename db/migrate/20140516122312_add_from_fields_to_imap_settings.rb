class AddFromFieldsToImapSettings < ActiveRecord::Migration
  def change
    add_column :imap_settings, :from_full_name, :string, limit: 250, null: false, default: ''
    add_column :imap_settings, :from_email, :string, limit: 250, null: false, default: ''
  end
end
