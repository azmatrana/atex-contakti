class AddAlarmReceiversColumnToPrioritiesTable < ActiveRecord::Migration
  def change
    add_column :priorities, :alarm_receivers, :text
  end
end
