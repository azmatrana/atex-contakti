class WaitingTasksWorker
  include ::Sidekiq::Worker
  sidekiq_options unique: true, retry: false

  def perform
    ::Task.to_warn_about_unlock.each do |task|
      task.push_waiting_timeout_alert
    end
    ::Task.should_unlock.each do |task|
      if task.state == 'waiting' && task.is_call?
        task.update_attributes({assigned_to_user_id: nil, state: 'new'})
      end
    end
  end
end