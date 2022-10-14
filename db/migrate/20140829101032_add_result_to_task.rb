class AddResultToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :result, :string, limit: 20, null: false, default: ''
  end
end
