class CreateWeeklySchedules < ActiveRecord::Migration
  def change
    create_table :weekly_schedules do |t|
      t.integer :schedulable_id
      t.string :schedulable_type
      t.boolean :open_full_time

      t.timestamps
    end
  end
end
