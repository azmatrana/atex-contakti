define(["jquery", "knockout", "i18next", "api"], function($, ko, i18n, api) {
    function SmsTemplate(data) {
        this.id = data.id;
        this.title = data.title;
        this.text = data.text;
        this.kind = data.kind;
        this.service_channel_id = data.service_channel_id;
        this.location_id = data.location_id;
        this.company_id = data.company_id;
        this.author_id = data.author_id;
        this.created_at = data.created_at;
        this.updated_at = data.updated_at;
        this.visibility = data.visibility;
    }

    SmsTemplate.fromArray = function(templates) {
        var models = [];

        if ($.isArray(templates)) {
            ko.utils.arrayForEach(templates, function(data) {
                models.push(new SmsTemplate(data));
            });
        }

        return models;
    };

    return SmsTemplate;
});
