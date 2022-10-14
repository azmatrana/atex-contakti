<% if @contact.save %>
  // $("#phonbook-contact-modal").modal('hide')
  $("#contacts-table-wrapper").html("<%= escape_javascript(render 'contacts/table', contacts: @contacts, public_phonebook: false) %>");
  var $savedAlert = $('.customer-saved-alert');
  $savedAlert.removeClass('hide');
  setTimeout(function () {
    $savedAlert.addClass('hide');
  }, 5000)
<% else %>
  alert("<%= @contact.errors.full_messages.to_sentence %>")
<% end %>
