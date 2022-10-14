class RemoveSmtpSettingsFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :smtp_settings_id, :integer
  end
end
