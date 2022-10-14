class PriorityAlarmWorker
  include Sidekiq::Worker

  def perform(tag_name, task_id, company_id)
    tag = ActsAsTaggableOn::Tag.where(name: tag_name).last
    return if tag.blank?

    priority = Priority.where(company_id: company_id, tag_id: tag.id).last

    if tag.present? && priority.present?
      priority.trigger_alarm(tag_name, task_id)
    end
  end
end
