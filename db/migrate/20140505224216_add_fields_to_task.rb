class AddFieldsToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :from, :string, limit: 250, null: false, default: ''
    add_column :tasks, :to,   :string, limit: 250, null: false, default: ''
    add_column :tasks, :in_reply_to_id, :integer
  end
end
