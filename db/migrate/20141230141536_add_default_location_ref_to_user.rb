class AddDefaultLocationRefToUser < ActiveRecord::Migration
  def change
    add_reference :users, :default_location, index: true
  end
end
