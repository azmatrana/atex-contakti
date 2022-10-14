class AddCallWaitDurationColumnsInAgentCallLogs < ActiveRecord::Migration
  def change
    add_column :agent_call_logs, :call_ring_start, :integer
    add_column :agent_call_logs, :call_ring_stop, :integer
    add_column :agent_call_logs, :call_ring_wait_seconds, :integer
    add_column :agent_call_logs, :call_duration_seconds, :integer


    AgentCallLog.all.each do |log|
      log.set_call_times
      log.save!
    end
  end
end
