class StatAddCallTaskCounters < ActiveRecord::Migration
  def change
    add_column :company_stats, :call_tasks_received, :integer, :default => 0, :null => false
    add_column :company_stats, :call_task_name_checks, :integer, :default => 0, :null => false
    add_column :company_stats, :call_task_autoreplies, :integer, :default => 0, :null => false
  end
end
