<% if @campaign.save %>
  var $savedAlert = $('.campaign-saved-alert');
  $savedAlert.removeClass('hide');
  setTimeout(function () {
    $savedAlert.addClass('hide');
  }, 5000)
<% else %>
  alert("<%= @campaign.errors.full_messages.to_sentence %>")
<% end %>
