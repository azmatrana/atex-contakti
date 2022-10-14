require 'redis'

class AgentOnlineStatusWorker
  include ::Sidekiq::Worker

  def clear_user_ids_key
    "danthes:clear_user_ids"
  end

  def perform
    redis = Redis.new
    clear_ids = JSON.parse(redis.get(self.clear_user_ids_key) || "[]")
    if clear_ids.any?
      puts "Agents #{clear_ids.to_s} have gone offline"
      params = {:went_offline_at => Time.current, :is_online => false}
      User.where('id IN (?)', clear_ids).update_all(params)
    end
    redis.set(self.clear_user_ids_key, [].to_json)
  end

end