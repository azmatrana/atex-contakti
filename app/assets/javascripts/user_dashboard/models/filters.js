//= require_self
//= require_tree ./filters

var Filters = {};

Filters.TaskFilters = function() {

    var self = this;
    this.filters = ko.observable({
        timeFilter:                ko.observable(new Filters.TimeFilter()),
        sortFilter:                ko.observable(new Filters.SortFilter()),
        searchFilter:              ko.observable(new Filters.SearchFilter()),
        assignFilter:              ko.observable(new Filters.AssignFilter()),
        channelFilter:             ko.observable(new Filters.ChannelFilter()),
        multiAssignFilter:         ko.observable(new Filters.MultiAssignFilter()),
        multiStateFilter:          ko.observable(new Filters.MultiStateFilter()),
        multiServiceChannelFilter: ko.observable(new Filters.MultiServiceChannelFilter()),
        multiMediaChannelFilter:   ko.observable(new Filters.MultiMediaChannelFilter()),
        multiSLAFilter:            ko.observable(new Filters.MultiSLAFilter()),
        multiTagFilter:            ko.observable(new Filters.MultiTagFilter()),
        multiFlagFilter:           ko.observable(new Filters.MultiFlagFilter()),
        multipleTicketsFilter:     ko.observable(new Filters.MultipleTicketsFilter()),
        domainFilter:              ko.observable(new Filters.DomainFilter()),
    });

    this.filterArray = function(array) {
        console.log("Added console in filterArray");
        console.log(array);
        return _.chain(array)
            .filter(self.filters().timeFilter().selected())
            .filter(self.filters().sortFilter().selected())
            .filter(self.filters().searchFilter().selected())
            .filter(self.filters().assignFilter().selected())
            .filter(self.filters().channelFilter().selected())
            .filter(self.filters().multiAssignFilter().selected())
            .filter(self.filters().multiStateFilter().selected())
            .filter(self.filters().multiServiceChannelFilter().selected())
            .filter(self.filters().multiMediaChannelFilter().selected())
            .filter(self.filters().multiSLAFilter().selected())
            .filter(self.filters().multiTagFilter().selected())
            .filter(self.filters().multiFlagFilter().selected())
            .filter(self.filters().multipleTicketsFilter().selected())
            .filter(self.filters().domainFilter().selected())
            .value();
    };

    this.filterForCounters = function(array) {
      return self.filterArray(array);
    };

    this.filterSortFilter = function(array) {
        return array.filter(self.filters().sortFilter().selected());
    };

};








