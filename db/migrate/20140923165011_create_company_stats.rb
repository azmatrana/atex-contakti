class CreateCompanyStats < ActiveRecord::Migration
  def change
    create_table :company_stats do |t|
      t.integer :company_id, null: false
      t.date :date, null: false
      t.integer :active_agents, null: false, default: 0
      t.integer :name_checks, null: false, default: 0

      t.timestamps
    end
  end
end
