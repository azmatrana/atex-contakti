class RemoveAllCallLogs < ActiveRecord::Migration
  def change
    AgentCallLog.delete_all
  end
end
