class DanthesPushWorker
  include ::Sidekiq::Worker
  sidekiq_options unique: true
  def perform(klass, id)
    # return if Rails.env.development?
    klass = klass.constantize
    # We want information about deleted_at timestamp changes too, therefore with_deleted
    object = klass.respond_to?(:with_deleted) ? klass.with_deleted.where(id: id).first : klass.find(id)
    ::DanthesService.new(object).push_to_browser
  end
end
