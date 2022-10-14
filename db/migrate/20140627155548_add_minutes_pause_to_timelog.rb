class AddMinutesPauseToTimelog < ActiveRecord::Migration
  def change
    add_column :timelogs, :minutes_paused, :integer, null: false, default: 0
  end
end
