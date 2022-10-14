define([
    "jquery",
    "knockout",
    "api",
    "models/service_channel",
    "models/media_channel"
], function(
    $,
    ko,
    api,
    ServiceChannel,
    MediaChannel
) {
    function Appdata()
    {
        this.serviceChannels = [];
        this.mediaChannels = [];
        this.availableTags = [];
        this.channelTypes = {
            email: 'MediaChannel::Email',
            call: 'MediaChannel::Call',
            internal: 'MediaChannel::Internal',
            web: 'MediaChannel::WebForm',
            chat: 'MediaChannel::Chat'
        };
        this.isDataLoaded = false;
        this.afterDataLoaded = [];

        if (api.currentUser) {
            this.loadData();
        }
    }

    Appdata.prototype.loadData = function() {
        var afterDataLoaded = function(scr, mcr, tlr) {
            this.serviceChannels = ServiceChannel.fromArray(scr[0]);
            this.mediaChannels = MediaChannel.fromArray(mcr[0]);
            this.availableTags = tlr[0];

            this.isDataLoaded = true;

            var self = this;
            $.each(this.afterDataLoaded, function(i, callback) {
                if (typeof callback === "function") {
                    callback.call(self);
                }
            });
            this.afterDataLoaded = [];
        };
        $.when(api.serviceChannels(), api.mediaChannels(), api.tagList()).done(
            afterDataLoaded.bind(this)
        );
    };

    Appdata.prototype.getChannelTypes = function() {
        return this.channelTypes;
    };

    Appdata.prototype.getServiceChannels = function() {
        return this.serviceChannels;
    };

    Appdata.prototype.getEmailServiceChannels = function() {
        var scids = [];
        ko.utils.arrayForEach(this.getMediaChannels(), function(mc) {
            if (!mc.broken && mc.type === 'MediaChannel::Email') {
                if (scids.indexOf(mc.service_channel_id) === -1) {
                    scids.push(mc.service_channel_id);
                }
            }
        });

        var serviceChannels = [];
        ko.utils.arrayForEach(this.getServiceChannels(), function(sc) {
            if (scids.indexOf(sc.id) > -1) {
                serviceChannels.push(sc);
            }
        });

        return serviceChannels;
    };

    Appdata.prototype.getMediaChannels = function() {
        return this.mediaChannels;
    };

    Appdata.prototype.getAvailableTags = function() {
        return this.availableTags;
    };

    Appdata.prototype.runAfterDataLoaded = function(callback) {
        if (this.isDataLoaded) {
            callback.call(this);
        } else {
            this.afterDataLoaded.push(callback);
        }
    };

    return new Appdata();
});
