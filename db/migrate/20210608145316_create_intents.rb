class CreateIntents < ActiveRecord::Migration
  def change
    create_table :intents do |t|
      t.string :intent
      t.references :company
      t.timestamps
    end
  end
end
