class AddTurnaroundTimeToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :turnaround_time, :integer, null: false, default: 0
  end
end
