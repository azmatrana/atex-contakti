class AddIsInternalToMessage < ActiveRecord::Migration
  def change
    add_column :messages, :is_internal, :boolean, null: false, default: false
  end
end
