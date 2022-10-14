class CreateAnswerImages < ActiveRecord::Migration
  def change
    create_table :answer_images do |t|
      t.string :file, null: false
      t.string :file_name, null: false
      t.integer :file_size
      t.string :file_type
      t.references :answer
      t.timestamps
    end
  end
end
