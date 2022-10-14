class AddAssignTimeToTask < ActiveRecord::Migration
  def up
    add_column :tasks, :assigned_at, :timestamp
    execute <<-SQL
      CREATE INDEX index_tasks_on_assigned_at_date ON tasks(date(assigned_at));
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX index_tasks_on_assigned_at_date;
    SQL
    remove_column :tasks, :assigned_at
  end

end
