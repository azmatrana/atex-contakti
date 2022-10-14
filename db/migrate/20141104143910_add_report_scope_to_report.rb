class AddReportScopeToReport < ActiveRecord::Migration
  def change
    add_column :reports, :report_scope, :string, limit: 20, null: false, default: ''
  end
end
