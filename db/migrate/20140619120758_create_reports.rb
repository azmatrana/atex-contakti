class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.string :title, limit: 100, null: false, default: ''
      t.string :kind, limit: 20, null: false, default: ''
      t.datetime :starts_at
      t.datetime :ends_at
      t.integer :company_id
      t.integer :author_id
      t.timestamps
    end
  end
end
