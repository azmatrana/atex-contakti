class CreateAnswerButtons < ActiveRecord::Migration
  def change
    create_table :answer_buttons do |t|
      t.string :text, null:false
      t.references :answer
      t.timestamps
    end
  end
end
