
Filters.StateFilter = function() {
    var self = this;
    this.state = ko.observable('new');

    this.selected = ko.observable(
        function(task) {
            if (self.state() === 'all')
                return true;
            return task.state() == self.state();
        }
    );
    this.set = function(filter) {
        self.state(filter);
    };
};

Filters.MultiStateFilterOptions = ['new', 'open', 'waiting', 'ready'];
Filters.MultiStateFilter = function() {
    var self = this;
    this.states = ko.observableArray(['new', 'open', 'waiting']);

    this.selected = ko.observable(
        function(task) {
          if(self.states().length == 0) { return true; }
          return self.states.indexOf(task.state()) > -1;
        }
    );
    this.set = function(filter) {
        if(!filter || filter.length == 0) {
          self.states(Filters.MultiAssignFilterOptions);
        } else {
          self.states(filter);
        }
    };
};
