class AddDealingTimeInChatbotStats < ActiveRecord::Migration
  def change
    add_column :chatbot_stats, :dealing_time, :bigint
  end
end
