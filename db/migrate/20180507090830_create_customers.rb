class CreateCustomers < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.string :first_name
      t.string :last_name
      t.string :person_phone
      t.string :person_email
      t.string :contact_phone
      t.string :contact_email
      t.string :contact_website
      t.string :contact_facebook
      t.string :contact_twitter
      t.string :contact_skype
      t.string :name
      t.string :address
      t.string :city
      t.string :country
      t.string :vat
      t.string :postcode
      t.references :company, index: true

      t.timestamps
    end
  end
end
