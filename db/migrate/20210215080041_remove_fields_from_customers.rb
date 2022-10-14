class RemoveFieldsFromCustomers < ActiveRecord::Migration
  def change
    remove_index :customers, :last_name

    remove_column :customers, :last_name
    remove_column :customers, :person_phone
    remove_column :customers, :person_email
    remove_column :customers, :contact_facebook
    remove_column :customers, :contact_twitter
    remove_column :customers, :contact_skype
  end
end
