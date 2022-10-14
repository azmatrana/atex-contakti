Views.MarkAsDoneDialog = function(task) {

  var self = this;

  this.task = task;

  this.selectedResult = ko.observable('neutral');

  this.selectedResult.subscribe(function() {
    // Emulate click on Fuel UX custom radio button.
    $(self.selectedResult.element[self.selectedResult()], 'i').first().click();
  });

  this.markAsDone = function() {
    self.task().close(self.selectedResult());
  };

};

Views.MarkAsDoneDialog.prototype = Views;
Views.MarkAsDoneDialog.prototype.constructor = Views.MarkAsDoneDialog;
