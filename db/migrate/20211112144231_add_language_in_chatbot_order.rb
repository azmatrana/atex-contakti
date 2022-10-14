class AddLanguageInChatbotOrder < ActiveRecord::Migration
  def change
    add_column :chatbot_orders, :preferred_language, :text, default: ""
  end
end

