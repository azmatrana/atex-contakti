class CleanupWorker
  include ::Sidekiq::Worker
  sidekiq_options unique: true

  def perform
    ::CleanupService.new.run
  end
end