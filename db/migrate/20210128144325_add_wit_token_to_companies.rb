class AddWitTokenToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :wit_token, :string, null: true
  end
end
