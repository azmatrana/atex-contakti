class RemoveApiUrlFromKimaiDetails < ActiveRecord::Migration
  def change
    remove_column :kimai_details, :api_url, :string
  end
end
