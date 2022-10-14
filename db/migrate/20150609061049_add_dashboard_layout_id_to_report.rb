class AddDashboardLayoutIdToReport < ActiveRecord::Migration
  def change
    add_column :reports, :dashboard_layout_id, :integer
  end
end
