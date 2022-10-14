define(["jquery", "knockout", "i18next"], function($, ko, i18n) {
    function ServiceChannel(data) {
        this.id = data.id;
        this.name = data.name;
        this.company_id = data.company_id;
        this.agents = data.agents;
    }

    ServiceChannel.fromArray = function(channels) {
        var models = [];

        if ($.isArray(channels)) {
            $.each(channels, function () {
                models.push(new ServiceChannel(this));
            });
        }

        return models;
    };

    return ServiceChannel;
});
