class CreateCartEmailTemplates < ActiveRecord::Migration
  def change
    create_table :cart_email_templates do |t|
      t.references :company
      t.string :name
      t.string :subject
      t.text   :body
      t.string :template_for
      t.timestamps
    end
  end
end
