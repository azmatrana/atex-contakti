class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.text :question
      t.references :intent
      t.references :company
      t.timestamps
    end
  end
end
