class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.string :title, limit: 250, null: false, default: ''
      t.text :description, null: false, default: ''
      t.string :state, limit: 100, null: false, default: ''
      t.integer :service_channel_id
      t.string :message_id, limit: 250, null: false, default: ''
      t.integer :message_uid
      t.timestamps
    end
  end
end
