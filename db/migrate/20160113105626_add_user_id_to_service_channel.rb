class AddUserIdToServiceChannel < ActiveRecord::Migration
  def change
    add_column :service_channels, :user_id, :integer
  end
end
