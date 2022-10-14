Views.MarkAsNewDialog = function(task) {

  var self = this;

  this.task = task;

  this.selectedResult = ko.observable('neutral');

  this.selectedResult.subscribe(function() {
    // Emulate click on Fuel UX custom radio button.
    $(self.selectedResult.element[self.selectedResult()], 'i').first().click();
  });

  this.markAsNew = function() {
    self.task().renew();
  };

};

Views.MarkAsNewDialog.prototype = Views;
Views.MarkAsNewDialog.prototype.constructor = Views.MarkAsNewDialog;
