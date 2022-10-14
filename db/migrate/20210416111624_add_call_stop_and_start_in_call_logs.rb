class AddCallStopAndStartInCallLogs < ActiveRecord::Migration
  def change
    add_column :agent_call_logs, :call_start, :bigint
    add_column :agent_call_logs, :call_stop, :bigint
  end
end
