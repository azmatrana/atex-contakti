class AddApiUrlInKimaiDetails < ActiveRecord::Migration
  def change
     add_column :kimai_details, :api_url, :string
  end
end
