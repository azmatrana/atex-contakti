class AddServiceChannelIdInChatOrder < ActiveRecord::Migration
  def change
    add_reference :chatbot_orders, :service_channel, index: true
  end
end
