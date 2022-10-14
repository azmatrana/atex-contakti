define(["jquery", "knockout", "i18next", "moment", "api"], function ($, ko, i18n, moment, api) {
  function Message(data) {
    var self = this;
    this._originalData = data;

    this._messageCreated(data);

    this.responseType = ko.computed(this.responseType.bind(this));
    this.created_at_i18n = moment(data.created_at).locale(i18n.options.lng).format('ddd l LT');
    this.canReply = ko.computed(this.canReply.bind(this));
    this.canReplyAll = ko.computed(this.canReplyAll.bind(this));
    this.canForward = ko.computed(this.canForward.bind(this));
    this.canDelete = ko.computed(this.canDelete.bind(this));
    if (data.attachments && data.attachments.length) {
      this.attachments = ko.observableArray(data.attachments);
    } else {
      this.attachments = ko.observableArray();
    }
    // console.log(data, this);
    this.internalCss = ko.pureComputed(function() {
      return self.isInternal() ? "reply-internal" : "reply-external";
    });
    this.isCallback = ko.pureComputed( function() {
      return [self.title().split(' ')[0], self.title().split(' ')[1]].join('_').toLowerCase() == 'callback_request'
    });
  }

  Message.prototype.getData = function () {
    return {
      task_id: this.task_id,
      user_id: this.user_id,
      channel_type: this.channel_type,
      created_at: this.created_at,
      from: this.from,
      from_email: this.from_email,
      is_internal: this.isInternal(),
      number: this.number,
      sms: this.sms,
      title: this.title(),
      to: this.to(),
      attachments: data.attachments,
      description: data.description(),
      formatted_description: data.formatted_description
    };
  };

  Message.fromArray = function (messages, task) {
    var models = [];

    if ($.isArray(messages)) {
      ko.utils.arrayForEach(messages, function (msg) {
        var data = msg;
        if (task) {
          data = $.extend(msg, {
            caller_name: task.caller_name()
          });
        }
        models.push(new Message(data));
      });
    }

    return models;
  };

  Message.prototype.isEmailType = function () {
    return this.channel_type == "email" || this.channel_type == "web_form";
  };

  Message.prototype.responseType = function () {
    if (this.isInternal()) {
      return 'internal';
    }
    return 'client';
  };

  Message.prototype.canReply = function () {
    return this.channel_type == "email";
  };
  Message.prototype.canReplyAll = function () {
    if(this._originalData.to){
      return this._originalData.to.split(',').length > 1;
    }
    else{
      return false;
    }
  };
  Message.prototype.canForward = function () {
    return this.isEmailType();
  };
  Message.prototype.canDelete = function () {
    return this.isEmailType();
  };

  Message.prototype._messageUpdated = function (data) {
    this.task_id = data.task_id;
    this.user_id = data.user_id;

    this.channel_type = data.channel_type;
    this.created_at = data.created_at;
    this.from = data.from;
    this.from_email = data.from_email;
    this.caller_name = data.caller_name;
    this.service_channel_name = data.service_channel_name;

    this.isInternal = ko.observable(data.is_internal);
    this.is_forward = false;
    this.number = data.number;
    this.sms = data.sms;
    this.in_reply_to_id = data.in_reply_to_id;
    this.inbound = data.inbound;

    if (this.sms && this.channel_type !== 'sms') {
      this.channel_type = 'call'
    }
    this.to = ko.observable(data.to);

    this.title = ko.observable(data.title);
    this.titleLabel = ko.computed(this.titleLabel.bind(this));

    this.attachments = data.attachments;

    this.description = ko.observable(data.description);
    this.formatted_description = data.formatted_description;
  };
  Message.prototype._messageCreated = function (data) {
    this.id = data.id;
    this._messageUpdated(data);
  };

  Message.prototype.titleLabel = function () {
    if (this.channel_type == "call") {
      if (this.sms) {
        if (this.in_reply_to_id) {
          return i18n.t('tasks.type.sms');
        } else {
          return i18n.t('tasks.type.sms') + ": " + this.to();
        }
      }
      var title = i18n.t('tasks.type.unanswered_call');
      if (this.caller_name && this.caller_name.length > 0) {
        title += " " + this.caller_name;
      }
      return title;
    }
    if (this.channel_type === "sms" && this.inbound) {
      return i18n.t('tasks.type.sms') + ": " + (this.caller_name || this._originalData.from);
    }

    if (this.channel_type === "sms" && !this.inbound) {
      return i18n.t('tasks.type.sms') + ": " + (this.caller_name || this._originalData.to);
    }
    return this.title();
  };

  Message.prototype.toLabel = function () {
    if (this.sms) {
      if (this.inbound) {
        return this.service_channel_name;
      } else {
        return this.to();
      }
    }
    if (this.channel_type === "call") {
      return this.service_channel_name;
    }
    return this.to();
  };

  Message.prototype.save = function () {
    if (this.id) {
      return this.update();
    }
    return this.create();
  };
  Message.prototype.update = function () {
    var data = this.getData();
    return api.patch('/messages/' + this.id, data).done(this._messageUpdated.bind(this));
  };
  Message.prototype.create = function () {
    var data = this.getData();
    data.user_id = api.currentUser.id;
    return api.post('/messages/', data).done(this._messageCreated.bind(this));
  };

  return Message;
});
