
Views.SmsForm = function(params) {
  var self = this;

  this.task = params.task;
  this.showFormObservable = params.showForm;

  this.selectedSmsTemplate = ko.observable();
  this.selectedSmsTemplateText = ko.observable('');
  this.cancelCallback = params.cancelCallback;

  this.selectedSmsTemplate.subscribe(function() {
    var text;
    _.forEach(self.task().data.service_channel.agent_sms_templates, function(template) {
      if(template.id == self.selectedSmsTemplate()) {
        text = template.text;
        return false;
      }
    });
    self.selectedSmsTemplateText(text);
    // Update the sms counter!
    window.SMSHelper.countRemainingChars($('.sms-message-input'));
  });

  if(this.task().firstMessage().data.channel_type === 'call') {
    this.number = ko.observable(self.task().firstMessage().from);
  } else if (this.task().data.media_channel === 'sms') {
    if(this.task().firstMessage().data.inbound) {
      this.number = ko.observable(this.task().firstMessage().data.from);
    } else {
      this.number = ko.observable(this.task().firstMessage().data.to);
    }
  } else {
    this.number = ko.observable();
  }


  Views.BaseForm.call(this);
};

_.extend(Views.SmsForm.prototype, new Views.BaseForm());
Views.SmsForm.prototype.constructor = Views.SmsForm;
