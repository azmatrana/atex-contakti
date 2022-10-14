let element = $("#contact-dynamic-show");
if ( element.length  == 0 )
{
  var wrapper = document.createElement("div");
  wrapper.id = "contact-dynamic-show"
  $("body").append(wrapper);
  element = $("#contact-dynamic-show");
}

<% if @contact %>
  element.html("<%= escape_javascript(render 'form', contact: @contact) %>");
  $("#phonbook-contact-modal").modal()
<% else %>
  alert("404")
<% end %>
