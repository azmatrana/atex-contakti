class AddCompanyIdToImapSettings < ActiveRecord::Migration
  def change
    add_column :imap_settings, :company_id, :integer
  end
end
