class AddDataToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :data, :json, null: false, default: '{}'
  end
end
