class AgentCampaign < ActiveRecord::Base

  belongs_to :campaign
  belongs_to :agent, class_name: 'User', foreign_key: 'agent_id'

end
