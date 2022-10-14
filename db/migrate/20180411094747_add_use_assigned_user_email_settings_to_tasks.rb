class AddUseAssignedUserEmailSettingsToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :use_assigned_user_email_settings, :boolean
  end
end
