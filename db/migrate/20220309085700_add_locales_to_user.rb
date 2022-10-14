class AddLocalesToUser < ActiveRecord::Migration
  def change
    add_column :users, :locale, :string, default: "fi"
  end
end
