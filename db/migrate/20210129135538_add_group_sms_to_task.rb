class AddGroupSmsToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :group_sms, :boolean, default: false
  end
end
