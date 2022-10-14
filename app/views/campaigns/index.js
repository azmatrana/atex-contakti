let element = $("#campaigns-dynamic-index");
if ( element.length  == 0 )
{
  var wrapper = document.createElement("div");
  wrapper.id = "campaigns-dynamic-index"
  $("body").prepend(wrapper);
  element = $("#campaigns-dynamic-index");
}

element.html("<%= escape_javascript(render 'campaigns', campaigns: @campaigns, call_icon: params[:call_icon] ) %>");
$("#campaigns-card-modal").modal('show')
