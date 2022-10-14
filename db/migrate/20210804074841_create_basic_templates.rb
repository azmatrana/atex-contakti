class CreateBasicTemplates < ActiveRecord::Migration
  def change
    create_table :basic_templates do |t|
      t.string :title, null: false
      t.text :text
      t.references :company
      t.timestamps
    end
  end
end
