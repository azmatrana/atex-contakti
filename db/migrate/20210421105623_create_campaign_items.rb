class CreateCampaignItems < ActiveRecord::Migration
  def change
    create_table :campaign_items do |t|
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :email
      t.string :website
      t.string :address
      t.string :city
      t.string :country
      t.string :vat
      t.string :postcode
      # t.references :company, index: true
      t.references :campaign, index: true

      t.timestamps
    end
  end
end
