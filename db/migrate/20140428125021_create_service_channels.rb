class CreateServiceChannels < ActiveRecord::Migration
  def change
    create_table :service_channels do |t|
      t.string :name, limit: 100, null: false, default: ''
      t.integer :imap_settings_id
      t.integer :smtp_settings_id
      t.timestamps
    end
  end
end
