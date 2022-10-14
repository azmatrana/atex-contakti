class CreateAnswers < ActiveRecord::Migration
  def change
    create_table :answers do |t|
      t.string :answer
      t.references :intent
      t.references :company
      t.timestamps
    end
  end
end
