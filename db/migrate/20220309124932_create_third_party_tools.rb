class CreateThirdPartyTools < ActiveRecord::Migration
  def change
    create_table :third_party_tools do |t|
      t.references :company
      t.text :content
      t.string :title
      t.timestamps
    end
  end
end
