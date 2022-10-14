class ServiceChannelDestroyWorker
  include ::Sidekiq::Worker
  def perform(id)
    begin
      ::ServiceChannel.find(id).destroy
    rescue
    end
  end
end
