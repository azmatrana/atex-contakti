class AddFieldsToServiceChannel < ActiveRecord::Migration
  def change
    add_column :service_channels, :yellow_alert_days, :integer
    add_column :service_channels, :yellow_alert_hours, :integer
    add_column :service_channels, :red_alert_days, :integer
    add_column :service_channels, :red_alert_hours, :integer
  end
end
