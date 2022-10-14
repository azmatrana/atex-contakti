class AddIsFromChatbotCustomActionButtonInTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :is_from_chatbot_custom_action_button, :boolean, default: false
  end
end
