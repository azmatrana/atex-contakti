class AddCustomerToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :customer_id, :integer
    add_index :tasks, :customer_id
  end
end
