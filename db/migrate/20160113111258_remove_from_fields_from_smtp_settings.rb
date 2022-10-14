class RemoveFromFieldsFromSmtpSettings < ActiveRecord::Migration
  def change
    remove_column :smtp_settings, :from_full_name, :string
    remove_column :smtp_settings, :from_email, :string
  end
end
