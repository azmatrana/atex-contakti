define(["jquery", "knockout", "i18next"], function($, ko, i18n) {
    function MediaChannel(data) {
        this.id = data.id;
        this.broken = data.broken;
        this.type = data.type;
        this.service_channel_id = data.service_channel_id;
    }

    MediaChannel.fromArray = function(channels) {
        var models = [];

        if ($.isArray(channels)) {
            $.each(channels, function () {
                models.push(new MediaChannel(this));
            });
        }

        return models;
    };

    return MediaChannel;
});
