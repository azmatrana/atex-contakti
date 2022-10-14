class CreateMediaChannels < ActiveRecord::Migration
  def change
    create_table :media_channels do |t|
      t.integer :service_channel_id
      t.string :type, limit: 20, null: false, default: ''
      t.integer :imap_settings_id
      t.integer :smtp_settings_id
      t.timestamps
    end
  end
end
