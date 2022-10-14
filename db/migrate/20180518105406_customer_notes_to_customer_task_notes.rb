class CustomerNotesToCustomerTaskNotes < ActiveRecord::Migration
  def change
    rename_table :customer_notes, :customer_task_notes
    add_column :customer_task_notes, :state, :integer, default: 0
  end
end
