class AddTimezoneToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :time_zone, :string, null: false, default: 'Helsinki'
  end
end
