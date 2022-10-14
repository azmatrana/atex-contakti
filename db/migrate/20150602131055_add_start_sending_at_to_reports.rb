class AddStartSendingAtToReports < ActiveRecord::Migration
  def change
    add_column :reports, :start_sending_at, :datetime
  end
end
