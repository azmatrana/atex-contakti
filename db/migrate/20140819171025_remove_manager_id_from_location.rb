class RemoveManagerIdFromLocation < ActiveRecord::Migration
  def up
    remove_column :locations, :manager_id
  end

  def down
    add_column :locations, :manager_id, :integer
  end

end
