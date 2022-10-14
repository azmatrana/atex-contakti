class AddChatInquiryFieldsInOrder < ActiveRecord::Migration
  def change
    add_column :chatbot_orders, :inquiry_fields_data, :text, default: ""
  end
end
