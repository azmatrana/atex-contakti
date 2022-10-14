class AgentSameCallUpdaterWorker
  include ::Sidekiq::Worker
  sidekiq_options retry: true

  def perform(log_id)
    sleep(1)
    agent_call_log = AgentCallLog.where(id: log_id).first
    return true if agent_call_log.blank?
    agent_call_log.remove_same_calls_from_other_agents
  end

end
