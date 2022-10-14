class AddMailSettingsToUser < ActiveRecord::Migration
  def change
    add_column :users, :smtp_settings_id, :integer
  end
end
