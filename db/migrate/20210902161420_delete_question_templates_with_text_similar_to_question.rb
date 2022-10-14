class DeleteQuestionTemplatesWithTextSimilarToQuestion < ActiveRecord::Migration
  def change
    QuestionTemplate.where("lower(text) in (?)", Question.pluck("lower(text)")).destroy_all
  end
end