class CreateAgentCallLogs < ActiveRecord::Migration
  def change
    create_table :agent_call_logs do |t|

      t.references :agent, index: true, foreign_key: {to_table: :users}

      t.string :caller_name
      t.string :clid
      t.string :flow
      t.string :sip_id
      t.string :call_status
      t.timestamps :call_start
      t.timestamps :call_stop
      t.string :uri

      t.timestamps
    end
  end
end
