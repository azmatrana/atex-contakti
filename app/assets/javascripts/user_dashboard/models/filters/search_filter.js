
Filters.SearchFilter = function() {
    var self = this;
    this.filter = ko.observable(null);

    this.selected = ko.observable(function(task) {
        if(self.filter() === null) return true;
        return _.contains(self.filter(), task.id);
    });

    this.set = function(params) {
        self.filter(params);
    };

};

