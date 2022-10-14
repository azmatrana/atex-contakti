let element = $("#contacts-dynamic-index");
if ( element.length  == 0 )
{
  var wrapper = document.createElement("div");
  wrapper.id = "contacts-dynamic-index"
  $("body").append(wrapper);
  element = $("#contacts-dynamic-index");
}

element.html("<%= escape_javascript(render 'contacts', contacts: @contacts, call_icon: params[:call_icon], public_phonebook: false ) %>");
$("#phonbook-card-modal").modal('show')
