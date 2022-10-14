class AddServiceChannelToChatbotStat < ActiveRecord::Migration
  def change
    add_reference :chatbot_stats, :service_channel, foreign_key: true
  end
end
