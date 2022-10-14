class AddLocationsManagersJoinTable < ActiveRecord::Migration
  def change
    create_table :locations_managers, id: false do |t|
      t.integer :location_id
      t.integer :manager_id
    end
  end
end
