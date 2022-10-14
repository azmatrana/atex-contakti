class AddCampaignItemIdInTask < ActiveRecord::Migration
  def change
    add_reference :tasks, :campaign_item, index: true
  end
end
