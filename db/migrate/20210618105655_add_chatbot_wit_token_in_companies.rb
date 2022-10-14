class AddChatbotWitTokenInCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :wit_chatbot_token, :string
    add_column :companies, :have_valid_wit_chatbot_token, :boolean, default: false
  end
end
