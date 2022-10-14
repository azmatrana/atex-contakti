class AddCheckoutFormatToChatSettings < ActiveRecord::Migration
  def change
  add_column :chat_settings ,:checkout_format, :string, default: "ticket"
  end
end
