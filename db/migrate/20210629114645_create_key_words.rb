class CreateKeyWords < ActiveRecord::Migration
  def change
    create_table :key_words do |t|
      t.string :text
      t.references :entity, null: false
    end
  end
end
