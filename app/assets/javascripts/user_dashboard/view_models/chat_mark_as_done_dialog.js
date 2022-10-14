
Views.ChatMarkAsDoneDialog = function() {

  var self = this;

  this.selectedResult = ko.observable('neutral');

  this.selectedResult.subscribe(function() {
    // Emulate click on Fuel UX custom radio button.
    $(self.selectedResult.element[self.selectedResult()], 'i').first().click();
  });

  this.markAsDone = function() {
    result = self.selectedResult();
    var channel_id = $('#chat_mark_as_done_modal').data('channel_id');
    $.ajax({
      url: channel_id + '/rate',
      method: 'POST',
      data: {result: result}
    });
  };

};

Views.ChatMarkAsDoneDialog.prototype = Views;
Views.ChatMarkAsDoneDialog.prototype.constructor = Views.ChatMarkAsDoneDialog;
