class CreateCampaigns < ActiveRecord::Migration
  def change
    create_table :campaigns do |t|
      t.string :name
      t.references :company, index: true

      t.references :agent, index: true, foreign_key: {to_table: :users}
      t.references :service_channel, index: true
      t.timestamps
    end
  end
end
