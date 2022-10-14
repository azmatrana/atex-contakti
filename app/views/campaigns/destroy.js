let form_entry = $("#edit_campaign_<%= @campaign.id %>")
<% if @campaign.present? and @campaign.destroy %>
  $("#campaign_items-card-modal").modal('hide')
  alert("<%= t('user_dashboard.delete_success') %>")
  if (form_entry.length > 0)
  {
    form_entry.remove();
  }
<%  elsif @campaign.blank? %>
  alert('404')
<%  else %>
  alert("<%= @campaign.errors.full_messages %>")
<%  end %>
