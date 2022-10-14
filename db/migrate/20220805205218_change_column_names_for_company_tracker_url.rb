class ChangeColumnNamesForCompanyTrackerUrl < ActiveRecord::Migration
  def change
    rename_column :companies, :api_url, :kimai_tracker_api_url
  end
end
