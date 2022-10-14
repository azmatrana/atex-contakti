class CreateTemplateReplies < ActiveRecord::Migration
  def change
    create_table :template_replies do |t|
      t.string :text
      t.references :company
      t.timestamps
    end
  end
end
