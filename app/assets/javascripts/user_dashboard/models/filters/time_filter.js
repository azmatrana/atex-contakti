
Filters.TimeFilter = function() {
    var self = this;
    this.time = ko.observable({});

    this.selected = ko.observable(
        function(task) {
            if(_.isEmpty(self.time()) || self.time() === '' || self.time().startDate === null || self.time().endDate === null)
                return true;
            var createdAt = moment(task.data.created_at);
            return createdAt.isAfter(self.time().startDate) && createdAt.isBefore(self.time().endDate);
        }
    );
    this.set = function(params) {
        self.time(params);
    };
};
