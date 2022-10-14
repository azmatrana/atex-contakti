class AddCurrencyToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :currency, :string, default: '€'
  end
end
