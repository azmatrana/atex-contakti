class AddApiUrlInCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :api_url, :string
  end
end
