class AddAttrsToDashboardLayout < ActiveRecord::Migration
  def change
    add_column :dashboard_layouts, :dashboard_default, :boolean, default: false
    add_column :dashboard_layouts, :report_default, :boolean, default: false
  end
end
