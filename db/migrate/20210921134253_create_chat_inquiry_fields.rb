class CreateChatInquiryFields < ActiveRecord::Migration
  def change
    create_table :chat_inquiry_fields do |t|
      t.string :title
      t.string :input_type, default: "text"
      t.references :chat_settings
    end
  end
end
