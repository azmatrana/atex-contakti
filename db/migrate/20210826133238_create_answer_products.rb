class CreateAnswerProducts < ActiveRecord::Migration
  def change
    create_table :chatbot_answer_products do |t|
      t.references :answer
      t.references :product
    end
  end
end
