class AddIndexesToCustomers < ActiveRecord::Migration
  def change
    add_index :customers, :person_phone
    add_index :customers, :person_email
    add_index :customers, :first_name
    add_index :customers, :last_name
  end
end
