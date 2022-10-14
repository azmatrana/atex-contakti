define([
    "knockout",
    "api"
], function(
    ko,
    api
) {
    function Email(data) {
        this.language = ko.observable(data.language);
        this.recipient = ko.observable(data.recipient);
        this.cc = ko.observable(data.cc);
        this.bcc = ko.observable(data.bcc);
        this.subject = ko.observable(data.subject);
        this.serviceChannelId = ko.observable(data.serviceChannelId);
        this.message = ko.observable(data.message);
    }

    Email.prototype.send = function() {
        return api.post('/tasks/send_email', {
            language: this.language,
            recipient: this.recipient,
            cc: this.cc,
            bcc: this.bcc,
            subject: this.subject,
            service_channel_id: this.serviceChannelId,
            message: this.message
        });
    };

    return Email;
});
