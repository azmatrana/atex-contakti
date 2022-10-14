class AddLocationsServiceChannelsJoinTable < ActiveRecord::Migration
  def change
    create_table :locations_service_channels, id: false do |t|
      t.integer :location_id
      t.integer :service_channel_id
    end
  end
end
