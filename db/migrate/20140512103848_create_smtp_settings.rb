class CreateSmtpSettings < ActiveRecord::Migration
  def change
    create_table :smtp_settings do |t|
      t.string :server_name, limit: 100, null: false, default: ''
      t.string :user_name, limit: 100, null: false, default: ''
      t.string :password, limit: 100, null: false, default: ''
      t.text :description, null: false, default: ''
      t.integer :port, null: false, default: 465
      t.boolean :use_ssl, null: false, default: true
      t.integer :company_id
      t.timestamps
    end
  end
end
