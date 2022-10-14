class CreateFonnectaCredentials < ActiveRecord::Migration
  def change
    create_table :fonnecta_credentials do |t|
      t.string :client_id, null: false
      t.string :client_secret, null: false
      t.string :token
      t.datetime :token_taken_at
      t.integer :token_expire_in
      t.timestamps
    end
  end
end
