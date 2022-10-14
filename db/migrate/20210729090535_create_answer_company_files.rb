class CreateAnswerCompanyFiles < ActiveRecord::Migration
  def change
    create_table :answer_company_files do |t|
      t.belongs_to :answer
      t.belongs_to :company_file
    end
  end
end
