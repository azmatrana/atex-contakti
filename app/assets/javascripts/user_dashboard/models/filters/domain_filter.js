Filters.DomainFilter = function() {
  var self = this;
  this.filter = ko.observable(null);
  this.selected = ko.observable(function(task) {
    if(self.filter() === null) return true;
    if(task.messages()[0].from && task.messages()[0].from.trim().endsWith(`@${self.filter()}`)) return task;
  });

  this.set = function(params) {
    self.filter(params);
  };

};