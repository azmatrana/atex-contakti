class AddMarkedAsReadToMessage < ActiveRecord::Migration
  def change
    add_column :messages, :marked_as_read, :boolean
  end
end
