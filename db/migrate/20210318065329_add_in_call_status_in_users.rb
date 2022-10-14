class AddInCallStatusInUsers < ActiveRecord::Migration
  def change
    add_column :users, :in_call, :boolean, default: false
  end
end
