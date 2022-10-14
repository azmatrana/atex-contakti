

Views.SearchBox = function() {

    var self = this;
    this.resultText = ko.observable("");
    this.resultData = ko.observable(null);

    this.searcher = new QueryThrottler(
        {
            timeout: 350,
            query: function (keyword) {
                return $.ajax({
                    url: '/tasks/search',
                    data: {q: keyword},
                    dataType: 'json'
                });
            },
            done: function (data) {
                self.resultData(data);
                self.filterChanged(data);

                self.changeText();
            }
        }
    );

    this.searchBox = ko.observable().extend({ rateLimit: 1200 });

    this.callbacks = {
        filterChanged: []
    };

    this.filterChanged = function(filters) {
        _.forEach(self.callbacks.filterChanged, function(func){
            func(filters);
        });
    };

    this.searchBox.subscribe(function() {
        self.searchBoxValueChanged();
    });

    this.searchBoxValueChanged = function() {
        if (_.isEmpty(self.searchBox())) {
            self.searchBoxEmpty();
        }
        else {
            self.resultText("...");
            self.searcher.query(self.searchBox());
        }
    };

    this.changeText = function() {
        var msg = I18n.t('search.results',
                        {count: window.userDashboardApp.filteredTasks().length});
        self.resultText(msg);
    };

    // Only state changed. Not need to search same string again. Performance fix
    this.stateChanged = function() {
        if (self.resultData()) {
            self.filterChanged(self.resultData());
            self.changeText();
        }
    };

    this.searchBoxEmpty = function() {
        self.resultText("");
        self.searcher.abort();
        self.filterChanged(null);
        self.resultData(null);
    };

};


Views.SearchBox.prototype = Views;

