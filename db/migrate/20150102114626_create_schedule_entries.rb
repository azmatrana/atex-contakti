class CreateScheduleEntries < ActiveRecord::Migration
  def change
    create_table :schedule_entries do |t|
      t.integer :weekly_schedule_id
      t.datetime :start_time
      t.datetime :end_time
      t.integer :weekday
      t.datetime :fixed_date

      t.timestamps
    end
  end
end
