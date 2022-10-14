class AddAddressFieldsInFonnecta < ActiveRecord::Migration
  def change
    add_column :fonnecta_contact_caches, :city_name, :string, default: ''
    add_column :fonnecta_contact_caches, :street_address, :string, default: ''
    add_column :fonnecta_contact_caches, :postal_code, :string, default: ''
    add_column :fonnecta_contact_caches, :post_office, :string, default: ''
  end
end
