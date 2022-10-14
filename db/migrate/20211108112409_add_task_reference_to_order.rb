class AddTaskReferenceToOrder < ActiveRecord::Migration
  def change
    add_reference :chatbot_orders, :task, index: true
  end
end
