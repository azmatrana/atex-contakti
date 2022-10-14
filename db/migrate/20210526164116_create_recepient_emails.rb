class CreateRecepientEmails < ActiveRecord::Migration
  def change
    create_table :recepient_emails do |t|
      t.string :email
      t.references :user, index: true

      t.timestamps
    end
  end
end
