class AddAlertFieldsToMediaChannels < ActiveRecord::Migration
  def change
    add_column :media_channels, :yellow_alert_hours, :decimal, precision: 4, scale: 2
    add_column :media_channels, :yellow_alert_days, :integer
    add_column :media_channels, :red_alert_hours, :decimal, precision: 4, scale: 2
    add_column :media_channels, :red_alert_days, :integer
  end
end
