
Filters.ChannelFilter = function() {
    var self = this;
    this.channelId = ko.observable("");
    this.selected = ko.observable(
        function(task) {
            if(self.channelId() === "")
                return true;
            return self.channelId() == task.data.service_channel_id
        }
    );
    this.set = function(filter) {
        self.channelId(filter);
    };

};

Filters.MultiServiceChannelFilter = function() {
    var self = this;
    this.channelIds = ko.observableArray();
    this.selected = ko.observable(
        function(task) {
            if(self.channelIds().length == 0) { return true; }
            return self.channelIds.indexOf(task.serviceChannelId().toString()) > -1;
        }
    );
    this.set = function(filter) {
        self.channelIds(filter);
    };
};

Filters.MultiMediaChannelFilterOptions = ['call', 'email', 'chat', 'web_form', 'internal', 'sms'];
Filters.MultiMediaChannelFilter = function() {
    var self = this;
    this.channelNames = ko.observableArray(Filters.MultiMediaChannelFilterOptions);
    this.selected = ko.observable(
        function(task) {
            if(self.channelNames().length == 0) { return true; }
            return self.channelNames.indexOf(task.data.media_channel) > -1;
        }
    );
    this.set = function(filter) {
        self.channelNames(filter);
    };
};
