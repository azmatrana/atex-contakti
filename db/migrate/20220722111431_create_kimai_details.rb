class CreateKimaiDetails < ActiveRecord::Migration
  def change
    create_table :kimai_details do |t|
      t.string :x_auth_user
      t.string :x_auth_token
      t.references :company

      t.timestamps
    end
  end
end
