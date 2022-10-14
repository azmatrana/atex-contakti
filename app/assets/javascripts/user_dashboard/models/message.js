
function TaskMessage(data, parent) {
  var self = this;
  this.data = data;
  this.id = data.id;
  this.parent = parent;
  this.cc = data.cc;
  this.bcc = data.bcc;

  this.from = (function () {
    if (parent.data.media_channel === 'chat') {
      if (parent.data.customer) {
        return parent.data.customer.contact_email || parent.data.customer.first_name || parent.data.customer.name
      } else if (data.from === 'Anonymous') {
        return;
      } else {
        return data.from;
      }
    } else {
      return data.from;
    }
  })();

  this.to = data.to;
  this.title = data.title;
  this.channel_type = data.channel_type;
  this.spinner = null;
  this.messageFetched = ko.observable(false);
  this.createdAt = data.created_at;
  this.isInternal = ko.observable(data.is_internal ? true : false);
  this.internalCss = ko.pureComputed(function() {
    return self.isInternal() ? "reply-internal" : "reply-external";
  });

  this.canReply = function() {
    var fromCurrentUser = window.UserDashboard.currentUserFromEmails.indexOf(self.from) >= 0;
    var isFirstMessage = this.data.number === 1;
    var isCall = !self.parent.data.is_not_call;
    var isSms = self.data.sms;
    var isChat = self.channel_type === 'chat';
    var isEmail = self.channel_type === 'email';
    var isWebForm = self.channel_type === 'web_form';
    var isSmsChannel = self.parent.data.media_channel === 'sms';
    return !_.isEmpty(data.from) && !isSmsChannel && !isCall && (isChat || isEmail || isWebForm || self.isInternal);
  };

  this.canReplyAll = function() {
    to_emails = self.data.to.split(',').length;
    cc_emails = 0;
    if(self.data.cc != null) {
      cc_emails = self.data.cc.length;
    }
    return to_emails + cc_emails > 1;
  };

  this.formatted_description = ko.observable(data.formatted_description);
  this.call_transcript       = ko.observable(data.call_transcript);

  if (data.attachments && data.attachments.length) {
    this.attachments = ko.observableArray(data.attachments);
  } else {
    this.attachments = ko.observableArray();
  }

  this.formattedDescription = ko.computed(function() {
    if(_.isEmpty(self.formatted_description())) {
/*    if(!self.messageFetched()) {*/
      self.spinner = new Spinner(UserDashboardOptions.spinnerOpts).spin();
      return self.spinner.el.outerHTML;
    } else {
      if(self.spinner) {
        self.spinner.stop();
        delete self.spinner;
      }
      return self.formatted_description();
      //return self.spinner.el.outerHTML;
    }
  });

  this.isCallback = ko.pureComputed( function() {
    return [self.title.split(' ')[0], self.title.split(' ')[1]].join('_').toLowerCase() == 'callback_request'
  });

  // Cannot serialize to JSON if we have circular reference.
  this.toJSON = function() {
    var cpy = ko.toJS(self);
    delete cpy.parent;
    return cpy;
  };
  console.log(parent.id);
  console.log(this);


}
