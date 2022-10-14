class CreateTimelogs < ActiveRecord::Migration
  def change
    create_table :timelogs do |t|
      t.integer :user_id
      t.integer :minutes_worked
      t.timestamps
    end
  end
end
