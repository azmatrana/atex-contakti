class ChangeTextTypeAnswerTemplatesAndAnswers < ActiveRecord::Migration
  def change
    change_column :template_replies, :text, :text
    change_column :answers, :text, :text
    change_column :question_templates, :text, :text
    change_column :questions, :text, :text
  end
end
