class AddEmailsToReport < ActiveRecord::Migration
  def change
    add_column :reports, :send_to_emails, :string, limit: 500, null: false, default: ''
  end
end
