class CreateImapSettings < ActiveRecord::Migration
  def change
    create_table :imap_settings do |t|
      t.string :server_name, limit: 100, null: false, default: ''
      t.string :user_name, limit: 100, null: false, default: ''
      t.string :password, limit: 100, null: false, default: ''
      t.text :description, null: false, default: ''
      t.timestamps
    end
  end
end
