class UpdateOpenTaskWorker
  include ::Sidekiq::Worker
  sidekiq_options unique: true, retry: false

  def perform(task)
    object = Task.where(id: task).first
    return true if object.blank?
    unless object.open_to_all
      object.update_attributes(open_to_all: true)
      ::DanthesService.new(object).push_to_browser
    end
  end
end
