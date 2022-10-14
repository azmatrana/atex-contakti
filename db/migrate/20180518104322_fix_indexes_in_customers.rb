class FixIndexesInCustomers < ActiveRecord::Migration
  def change
    remove_index :customers, :person_email
    remove_index :customers, :person_phone
    add_index :customers, :contact_email
    add_index :customers, :contact_phone
  end
end
