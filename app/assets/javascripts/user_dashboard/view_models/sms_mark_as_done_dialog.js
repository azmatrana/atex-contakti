Views.SmsMarkAsDoneDialog = function(task) {

  var self = this;

  this.task = task;

  this.markAsDone = function() {
    self.task().close();
  };

};

Views.SmsMarkAsDoneDialog.prototype = Views;
Views.SmsMarkAsDoneDialog.prototype.constructor = Views.SmsMarkAsDoneDialog;
