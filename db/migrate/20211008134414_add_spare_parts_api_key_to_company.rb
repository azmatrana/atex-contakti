class AddSparePartsApiKeyToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :spare_parts_api_key, :string, default: ""
  end
end
