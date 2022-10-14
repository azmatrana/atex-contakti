class CreateMessages < ActiveRecord::Migration
  def change
    enable_extension 'uuid-ossp'
    create_table :messages, :id => :uuid do |t|
      t.integer :number, null: false, default: 1
      t.string :from, limit: 250, null: false, default: ''
      t.string :to, limit: 250, null: false, default: ''
      t.string :title, limit: 250, null: false, default: ''
      t.text :description, null: false, default: ''
      t.integer :message_uid
      t.uuid :in_reply_to_id
      t.integer :task_id
      t.timestamps
    end
  end
end
