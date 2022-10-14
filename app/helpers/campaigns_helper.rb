module CampaignsHelper

  def service_channels_collection_for_campaign
    @service_channels = ::ServiceChannel.shared.accessible_by(current_ability)
    @service_channels.map{|sc| [sc.name, sc.id]}
  end

  def agents_collection
    current_user.company.agents.map{|agent| [agent.full_name_format, agent.id]}
  end

  def campaign_item_in_call(_campaign_item)
    if _campaign_item.agent_call_logs.length > 0
       last_call = _campaign_item.agent_call_logs.last
       return ['ended', 'missed'].include?(last_call.call_status) ? false : true
    else
      return false
    end
  end

  def campaing_data_for_task(_campaign_item)
    html  = "<p> #{_campaign_item.first_name} #{_campaign_item.last_name}</p>"
    html += "<p> #{_campaign_item.phone} #{_campaign_item.email}</p>"
    html += "<p> #{_campaign_item.address} #{_campaign_item.postcode}</p>"
    html += "<p> #{_campaign_item.city} #{_campaign_item.country}</p>"
  end
end

