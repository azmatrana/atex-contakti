class RenameQuestionAndIntentsTextColumn < ActiveRecord::Migration
  def change
    rename_column :questions, :question, :text
    rename_column :answers, :answer, :text
    rename_column :intents, :intent, :text
  end
end
