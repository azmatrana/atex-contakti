class AddWentOfflineAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :went_offline_at, :datetime
  end
end
