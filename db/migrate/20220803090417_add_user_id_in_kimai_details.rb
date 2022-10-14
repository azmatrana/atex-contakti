class AddUserIdInKimaiDetails < ActiveRecord::Migration
  def change
    add_column :kimai_details, :user_id, :integer
  end
end
