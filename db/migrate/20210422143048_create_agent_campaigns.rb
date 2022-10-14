class CreateAgentCampaigns < ActiveRecord::Migration
  def change
    create_table :agent_campaigns do |t|
      t.references :campaign, index: true
      t.references :agent, index: true, foreign_key: {to_table: :users}

      t.timestamps
    end
  end
end
