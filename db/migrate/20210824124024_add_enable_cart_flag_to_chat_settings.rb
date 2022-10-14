class AddEnableCartFlagToChatSettings < ActiveRecord::Migration
  def change
    add_column :chat_settings, :enable_cart, :boolean, default: false
  end
end
