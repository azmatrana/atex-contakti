class AddAliasNameToUser < ActiveRecord::Migration
  def change
    add_column :users, :alias_name, :string, limit: 100, null: false, default: ''
  end
end
