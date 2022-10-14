class CreateSipSettings < ActiveRecord::Migration
  def change
    create_table :sip_settings do |t|
      t.string :title, null: false
      t.string :user_name, null: false
      t.string :password, null: false
      t.string :domain, null: false
      t.string :ws_server_url, null: false

      t.belongs_to :company

      t.timestamps
    end
  end
end
