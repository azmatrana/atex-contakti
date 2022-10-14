class CalculateTaskTurnaroundTime < ActiveRecord::Migration
  def up
    ::Task.connection.schema_cache.clear!
    ::Task.reset_column_information
    ::Task.unscoped do
      ::Task.where(state: 'ready').each do |task|
        task.versions.each do |version|
          task_at_version = version.reify
          next unless task_at_version
          task.opened_at = version.created_at if task_at_version.open? && !task.opened_at
          if task.opened_at && task_at_version.ready? && task.turnaround_time == 0
            task.turnaround_time = ((version.created_at - task.opened_at) / 60).floor
            break
          end
        end
        task.save if task.changed?
      end
    end
  end

  def down
    ::Task.unscoped do
      ::Task.where(state: 'ready').update_all(turnaround_time: 0, opened_at: nil)
    end
  end
end
