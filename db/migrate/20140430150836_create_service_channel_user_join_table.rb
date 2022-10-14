class CreateServiceChannelUserJoinTable < ActiveRecord::Migration
  def change
    create_table :service_channels_users, id: false do |t|
      t.integer :service_channel_id
      t.integer :user_id
    end
  end
end
