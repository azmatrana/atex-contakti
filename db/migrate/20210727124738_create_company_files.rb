class CreateCompanyFiles < ActiveRecord::Migration
  def change
    create_table :company_files do |t|
      t.string :file, null: false
      t.string :file_name, null: false
      t.integer :file_size
      t.string :file_type
      t.references :company
      t.timestamps
    end
  end
end
