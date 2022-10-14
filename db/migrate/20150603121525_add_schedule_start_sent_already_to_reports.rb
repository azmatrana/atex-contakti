class AddScheduleStartSentAlreadyToReports < ActiveRecord::Migration
  def change
    add_column :reports, :schedule_start_sent_already, :boolean, null: false, default: false
  end
end

