class AddReportsServiceChannelsJoinTable < ActiveRecord::Migration
  def change
    create_table :reports_service_channels, id: false do |t|
      t.integer :report_id
      t.integer :service_channel_id
    end
  end
end
