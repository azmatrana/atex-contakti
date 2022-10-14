class AddReportsUsersJoinTable < ActiveRecord::Migration
  def change
    create_table :reports_users, id: false do |t|
      t.integer :report_id
      t.integer :user_id
    end
  end
end
