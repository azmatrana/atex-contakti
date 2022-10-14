class Campaign < ActiveRecord::Base
  belongs_to :company
  has_many :campaign_items, dependent: :destroy
  belongs_to :service_channel

  has_many :agent_campaigns, dependent: :destroy
  has_many :agents, through: :agent_campaigns

  scope :sort_by, ->  sort_item, direction { if ["name"].include?(sort_item)
    order("#{sort_item}": direction)
    end
  }
end
