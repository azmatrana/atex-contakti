class ChangeCampaignItemFieldsNames < ActiveRecord::Migration
  def change
     rename_column :campaign_items, :website, :info_1
     rename_column :campaign_items, :vat, :info_2
  end
end
