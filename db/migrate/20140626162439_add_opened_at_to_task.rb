class AddOpenedAtToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :opened_at, :datetime
  end
end
