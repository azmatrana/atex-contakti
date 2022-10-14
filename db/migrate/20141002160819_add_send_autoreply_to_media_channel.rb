class AddSendAutoreplyToMediaChannel < ActiveRecord::Migration
  def change
    add_column :media_channels, :send_autoreply, :boolean, null: false, default: true
  end
end
