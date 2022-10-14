<% if @campaign_item.save %>
  // $("#phonbook-campaign_item-modal").modal('hide')
  $("#campaign_items-table-wrapper").html("<%= escape_javascript(render 'campaign_items/table/table', campaign_items: @campaign_items, campaign: @campaign, is_admin: @is_admin) %>");
  var $savedAlert = $('.customer-saved-alert');
  $savedAlert.removeClass('hide');
  setTimeout(function () {
    $savedAlert.addClass('hide');
  }, 5000)
<% else %>
  alert("<%= @campaign_item.errors.full_messages.to_sentence %>")
<% end %>
