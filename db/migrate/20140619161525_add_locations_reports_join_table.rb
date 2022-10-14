class AddLocationsReportsJoinTable < ActiveRecord::Migration
  def change
    create_table :locations_reports, id: false do |t|
      t.integer :location_id
      t.integer :report_id
    end
  end
end
