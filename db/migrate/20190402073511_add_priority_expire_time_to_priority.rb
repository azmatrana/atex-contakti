class AddPriorityExpireTimeToPriority < ActiveRecord::Migration
  def change
    add_column :priorities, :expire_time, :integer
  end
end
