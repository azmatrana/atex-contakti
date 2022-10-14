class CreateUserSessions < ActiveRecord::Migration
  def change
    create_table :user_sessions do |t|
      t.uuid :session_id, null: false
      t.integer :user_id, null: false
      t.string :user_ip
      t.string :user_agent
      t.timestamp :accessed_at

      t.timestamps
    end
    add_index :user_sessions, :user_id
    add_index :user_sessions, [:user_id, :session_id]
    add_index :user_sessions, :session_id, unique: true
  end
end
