let element = $("#campaign_item-dynamic-show");
if ( element.length  == 0 )
{
  var wrapper = document.createElement("div");
  wrapper.id = "campaign_item-dynamic-show"
  $("body").append(wrapper);
  element = $("#campaign_item-dynamic-show");
}

<% if @campaign_item %>
  element.html("<%= escape_javascript(render 'form', campaign_item: @campaign_item, is_admin: @is_admin) %>");
  $("#phonbook-campaign_item-modal").modal()
<% else %>
  alert("404")
<% end %>
