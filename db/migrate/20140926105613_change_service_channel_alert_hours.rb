class ChangeServiceChannelAlertHours < ActiveRecord::Migration
  def change
    change_column :service_channels, :red_alert_hours,    :decimal, precision: 4, scale: 2
    change_column :service_channels, :yellow_alert_hours, :decimal, precision: 4, scale: 2
  end
end
