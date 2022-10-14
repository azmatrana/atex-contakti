class CreateTrackerDetails < ActiveRecord::Migration
  def change
    create_table :tracker_details do |t|
      t.integer :tracker_id
      t.references :task
      t.timestamps
    end
  end
end
