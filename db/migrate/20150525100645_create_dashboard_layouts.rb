class CreateDashboardLayouts < ActiveRecord::Migration
  def change
    create_table :dashboard_layouts do |t|
      t.string :name
      t.integer :size_x
      t.integer :size_y
      t.integer :company_id
      t.boolean :default

      t.timestamps
    end
  end
end
