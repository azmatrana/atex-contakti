let table_el = $("#campaign_item-row-<%= @campaign_item.id %>")
<% if @campaign_item.present? and @campaign_item.destroy %>
  $("#phonbook-campaign_item-modal").modal('hide')
  alert("<%= t('user_dashboard.delete_success') %>")
  $("#dynamic-content-child").html("");
  if (table_el.length > 0)
  {
    table_el.remove();
  }
<%  elsif @campaign_item.blank? %>
  alert('404')
<%  else %>
  alert("<%= @campaign_item.errors.full_messages %>")
<%  end %>

