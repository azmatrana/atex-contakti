class AddCallAbleRelationInLogs < ActiveRecord::Migration
  def change
    add_reference :agent_call_logs, :callable, index: true, polymorphic: true
  end
end
