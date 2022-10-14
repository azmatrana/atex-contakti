class CreateCredentialsTavoittajas < ActiveRecord::Migration
  def change
    create_table :credentials_tavoittajas do |t|
      t.string :username, null: false
      t.string :password, null: false

      t.timestamps
    end
  end
end
