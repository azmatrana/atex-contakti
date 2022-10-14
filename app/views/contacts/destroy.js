let table_el = $("#contact-row-<%= @contact.id %>")
<% if @contact.present? and @contact.destroy %>
  $("#phonbook-contact-modal").modal('hide')
  alert("<%= t('user_dashboard.delete_success') %>")
  $("#dynamic-content-child").html("");
  if (table_el.length > 0)
  {
    table_el.remove();
  }
<%  elsif @contact.blank? %>
  alert('404')
<%  else %>
  alert("<%= @contact.errors.full_messages %>")
<%  end %>

