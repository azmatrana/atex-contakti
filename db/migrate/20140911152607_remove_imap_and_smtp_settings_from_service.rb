class RemoveImapAndSmtpSettingsFromService < ActiveRecord::Migration
  def change
    remove_column :service_channels, :imap_settings_id
    remove_column :service_channels, :smtp_settings_id
  end
end
