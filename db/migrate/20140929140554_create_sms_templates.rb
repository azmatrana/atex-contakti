class CreateSmsTemplates < ActiveRecord::Migration
  def change
    create_table :sms_templates do |t|
      t.string :title, limit: 100, null: false, default: ''
      t.text :text
      t.string :kind, limit: 20, null: false, default: ''
      t.integer :service_channel_id
      t.integer :location_id
      t.integer :company_id
      t.integer :author_id
      t.timestamps
    end
  end
end
