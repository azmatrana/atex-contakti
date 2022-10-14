class AddInactiveToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :inactive, :boolean, default: false
  end
end
