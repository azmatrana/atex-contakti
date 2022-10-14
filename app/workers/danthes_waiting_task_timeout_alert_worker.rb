class DanthesWaitingTaskTimeoutAlertWorker
  include ::Sidekiq::Worker
  sidekiq_options unique: true
  def perform(klass, id)
    object = klass.constantize.find(id)
    ::DanthesService.new(object).alert_expiring_waiting_task_to_browser
  end
end