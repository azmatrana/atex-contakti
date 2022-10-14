Filters.MultipleTicketsFilter = function() {
  var self = this;
  this.filter = ko.observable(null);

  this.selected = ko.observable(function(task) {
    if(self.filter() === null) return true;
     if(self.filter() === task.messages()[0].from) return task;
  });
  this.set = function(params) {
    self.filter(params);
  };

};