Filters.SortFilter = function() {
    var self = this;
    this.filter = ko.observable('');

    this.selected = ko.observable(function(task) {
        if(self.filter() == '') return true;
        switch(self.filter().type) {
            case 'channel':
                return task.data.media_channel == self.filter().value;
            case 'sla':
                if (self.filter().value == 'red')
                    return Number(task.data.minutes_till_red_alert) < 0;
                else {
                    return (Number(task.data.minutes_till_red_alert) > 0 && Number(task.data.minutes_till_yellow_alert) < 0)
                }

            default:
                return true;
        }
    });

    this.set = function(params) {
        if(_.isEmpty(params)) self.filter('');
        else {
            var filters = params.split('-');
            self.filter({type: filters[0], value: filters[1]});
        }
    };

};

Filters.MultiSLAFilterOptions = []
Filters.MultiSLAFilter = function() {
    var self = this;
    this.filters = ko.observableArray(Filters.MultiSLAFilterOptions);

    this.selected = ko.observable(function(task) {
      if(self.filters().length == 0) { return true; }
      if(self.filters().indexOf('no_alert') > -1 && task.data.minutes_till_yellow_alert > 0 && task.data.minutes_till_red_alert > 0) { return true; }
      if(self.filters().indexOf('yellow_alert') > -1 && task.data.minutes_till_yellow_alert <= 0 && task.data.minutes_till_red_alert > 0) { return true; }
      if(self.filters().indexOf('red_alert') > -1 && task.data.minutes_till_red_alert <= 0) { return true; }
      return false;
    });

    this.set = function(params) {
      self.filters(params);
    };
};
