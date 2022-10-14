Views.MessageCounters = function (tasks, isReadyFilter, parent) {

  var self = this;
  this.tasks = tasks;
  this.isReadyFilter = isReadyFilter;

  this.parent = parent;

  this.moreReady = ko.observable(true);

  this.callbacks = {
    filterChanged: []
  };

  this.taskCounterNew = ko.pureComputed(function () {
    return ko.utils.arrayFilter(self.tasks(), function (obj) {
      return obj.state() == 'new';
    }).length;
  });
  this.taskCounterOpen = ko.pureComputed(function () {
    return ko.utils.arrayFilter(self.tasks(), function (obj) {
      return obj.state() == 'open';
    }).length;
  });
  this.taskCounterWaiting = ko.pureComputed(function () {
    return ko.utils.arrayFilter(self.tasks(), function (obj) {
      return obj.state() == 'waiting';
    }).length;
  });
  this.taskCounterReady = ko.pureComputed(function () {
    //var plus = '';
    /*if(self.moreReady()) {
      plus = '+';
    }*/
    //return ko.utils.arrayFilter(self.tasks(), function(obj) { return obj.state() == 'ready'; } ).length + plus;
    return ko.utils.arrayFilter(self.tasks(), function (obj) {
      return obj.state() == 'ready';
    }).length;
  });

  this.filterChanged = function (filter) {
    _.forEach(self.callbacks.filterChanged, function (func) {
      func(filter);
    });
  };

  this.filterClicked = function (filter) {
    self.filterChanged(filter);
  };


  $('#message_counters').html(JST['templates/tasks/message_counters']());

    $('#task-list-container').scroll($.debounce( 250, function(){
        console.log('SCROLLING!');
        if ( ($('#task-list-container').scrollTop() + $('#task-list-container').innerHeight() + 50) >= $('#task-list-container')[0].scrollHeight)
        {
          console.log('SCROLLING Almost End!');
          if (self.moreReady()) {
            console.log('SCROLLING ready tasks!');
            self.parent.fetchMoreReadyTasks();
          }
        }
    }));

  return this;
};

Views.MessageCounters.prototype = Views;
