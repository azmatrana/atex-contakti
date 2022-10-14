Filters.MultiSkillFilter = function() {
    var self = this;
    this.skills = ko.observableArray();
    this.selected = ko.observable(
        function(task) {
            if(self.skills().length == 0) { return true; }
            var taskTags = ko.utils.arrayMap(task.skills(), function(item) { return item.name; });
            return _.intersection(self.skills(), taskTags).length > 0
        }
    );
    this.set = function(filter) {
        self.skills(filter);
    };
};

Filters.MultiGenericTagFilter = function() {
    var self = this;
    this.generic_tags = ko.observableArray();
    this.selected = ko.observable(
        function(task) {
            if(self.generic_tags().length == 0) { return true; }
            var taskTags = ko.utils.arrayMap(task.generic_tags(), function(item) { return item.name; });
            return _.intersection(self.generic_tags(), taskTags).length > 0
        }
    );
    this.set = function(filter) {
        self.generic_tags(filter);
    };
};

Filters.MultiTagFilter = function() {
    var self = this;
    this.tags = ko.observableArray();
    this.selected = ko.observable(
        function(task) {
            if(self.tags().length == 0) { return true; }
            var taskTags = ko.utils.arrayMap(task.generic_tags(), function(item) { return item.name; }).concat(ko.utils.arrayMap(task.skills(), function(item) { return item.name; }));
            return _.intersection(self.tags(), taskTags).length > 0
        }
    );
    this.set = function(filter) {
        self.tags(filter);
    };
};

Filters.MultiFlagFilter = function() {
    var self = this;
    this.flags = ko.observableArray();
    this.selected = ko.observable(
        function(task) {
            if(self.flags().length == 0) { return true; }
            var taskTags = ko.utils.arrayMap(task.flags(), function(item) { return item.name; });
            return _.intersection(self.flags(), taskTags).length > 0
        }
    );
    this.set = function(filter) {
        self.flags(filter);
    };
};

