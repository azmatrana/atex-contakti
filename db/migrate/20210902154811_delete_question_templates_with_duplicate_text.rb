class DeleteQuestionTemplatesWithDuplicateText < ActiveRecord::Migration
  def change
    Question.all.each do |q|
      text = q.text.squish
      q.update_column(:text, text)
    end

    QuestionTemplate.all.each do |q|
      text = q.text.squish
      q.update_column(:text, text)
    end

    grouped = QuestionTemplate.all.group_by { |model| [model.text, model.company_id] }
    grouped.values.each do |duplicates|
      first_one = duplicates.shift
      duplicates.each { |double| double.destroy }
    end


    grouped = Question.all.group_by { |model| [model.text, model.company_id] }
    grouped.values.each do |duplicates|
      first_one = duplicates.shift
      duplicates.each { |double| double.destroy }
    end
  end
end
