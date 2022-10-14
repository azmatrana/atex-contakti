class CreateChatbotCustomers < ActiveRecord::Migration
  def change
    create_table :chatbot_customers do |t|
      t.string :full_name
      t.string :email
      t.string :phone_number
      t.string :street_address
      t.string :city
      t.string :zip_code
      t.timestamps
    end
  end
end
