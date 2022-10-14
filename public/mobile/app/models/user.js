define([
    "knockout"
], function(
    ko
) {
    function User(data) {
        this.id = data.id;
        this.email = data.email;
        this.token = data.token;

        this.firstName = data.first_name;
        this.lastName = data.last_name;
        this.title = data.title;
        this.mobile = data.mobile;
        this.signature = data.signature;

        this.mediaChannels = data.media_channels;
        this.serviceChannels = data.service_channels;
    }

    User.prototype.getData = function() {
        var self = this;
        return {
            id: self.id,
            email: self.email,
            token: self.token,
            first_name: self.firstName,
            last_name: self.lastName,
            title: self.title,
            mobile: self.mobile,
            signature: self.signature
        };
    };

    return User;
});
