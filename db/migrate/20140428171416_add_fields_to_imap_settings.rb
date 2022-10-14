class AddFieldsToImapSettings < ActiveRecord::Migration
  def change
    add_column :imap_settings, :port, :integer, default: 143
    add_column :imap_settings, :use_ssl, :boolean, default: false
  end
end
