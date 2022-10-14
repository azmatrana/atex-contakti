class AddDescriptionToChatbotProducts < ActiveRecord::Migration
  def change
    add_column :chatbot_products, :description, :text, default: ''
  end
end
