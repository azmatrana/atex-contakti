class AddFromFieldsToSmtpSettings < ActiveRecord::Migration
  def change
     add_column :smtp_settings, :from_full_name, :string
     add_column :smtp_settings, :from_email, :string
  end
end
