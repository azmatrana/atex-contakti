class AddFieldToDashboardLayout < ActiveRecord::Migration
  def change
    add_column :dashboard_layouts, :layout, :text
  end
end
