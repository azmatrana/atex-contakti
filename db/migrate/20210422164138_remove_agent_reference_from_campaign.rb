class RemoveAgentReferenceFromCampaign < ActiveRecord::Migration
  def change
    remove_reference :campaigns, :agent, index: true, foreign_key: {to_table: :users}
  end
end
