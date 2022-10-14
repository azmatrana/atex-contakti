class AddVisibleInAgentCallLogs < ActiveRecord::Migration
  def change
    add_column :agent_call_logs, :visible, :boolean, default: true
  end
end
