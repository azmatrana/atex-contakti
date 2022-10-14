class CreateQuestionTemplates < ActiveRecord::Migration
  def change
    create_table :question_templates do |t|
      t.string :text, null: false
      t.references :company
    end
  end
end
