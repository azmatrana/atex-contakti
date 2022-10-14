function ServiceChannelResult(data) {
  var self = this;
  this.id = data[0];
  this.name = data[1];
  this.signature = data[2];
}

Views.ReplyForm = function(params) {

  var self = this;

  this.task = params.task;
  this.showFormObservable = params.showForm;
  this.selectedMessage = this.task().firstNotSmsMessage();
  this.messageText = ko.observable('');
  this.onlyInternal = params.onlyInternal;
  this.internal = ko.observable(this.onlyInternal());
  this.cancelCallback = params.cancelCallback;
  this.replyAll = params.replyAll;
  this.signatures = ko.observableArray([]);
  this.signatureSelected = ko.observable();
  this.lastSignature = ko.observable(this.signatureSelected());
  this.messageWithoutSignature = ko.observable(this.messageText());
  this.templateText = ko.observable();
  this.isEditorChanged = false;
  this.companyFiles = ko.observableArray([]);

  this.showFormObservable.subscribe(function(newValue) {
    self.internal(self.onlyInternal());
  });

  this.signatureSelected.subscribe(function(oldValue) {
    self.lastSignature(oldValue);
  }, null, "beforeChange");

  if(window.userSignature) {
    this.messageText(this.messageText() + "<br><br>" + window.userSignature);
  }

  this.loadAllServiceChannels = function () {
    let serviceChannel = this.task().data.service_channel;
    let signatures = [];
    if(serviceChannel.signature) {
      signatures.push(new ServiceChannelResult([serviceChannel.id, serviceChannel.name, serviceChannel.signature]))
    }

    if (window.userSignature) {
      signatures.push(new ServiceChannelResult(['agent', I18n.t('user_dashboard.user_dashboard_mailer.agent'), window.userSignature]));
    }
    return signatures;
  };

  this.make_chain = function(message) {
    var whole_msg = message.formattedDescription();
    var pos = whole_msg.indexOf("[Task ID");
    whole_msg = whole_msg.substring(0, pos);
    whole_msg = whole_msg.replaceAll('<br/>', '<br/>> ').replaceAll('<br />', '<br/>> ');
    var from = message.from === undefined ? '' : message.from.replace('<', '').replace('>', '');
    return "<br/><br/>" + from + ' ' + moment(message.createdAt).format('DD.MM.YYYY HH:mm') + " wrote: <br/><br/>> " + whole_msg;
  };

  var msg = this.make_chain(this.task().firstNotSmsMessage());
  this.messageText(msg);

  if (this.task().data.draft) {
    this.messageText(this.task().data.draft.description);
  }

  this.getReplyToEmails = function() {
    var replyToEmails;
    var replyToCc;
    var replyToEmails2;

    debugger
    if (self.onlyInternal()) {
      replyToEmails = '';
    } else if (self.replyAll()) {
      replyToEmails = [self.selectedMessage.from];
      if(self.selectedMessage.cc != null) {
        if (typeof self.selectedMessage.cc === 'string' || self.selectedMessage.cc instanceof String) {
          replyToCc = self.selectedMessage.cc.split(',');
        } else {
          replyToCc = self.selectedMessage.cc;
        }
        replyToEmails = replyToCc.concat(replyToEmails);
      }
      replyToEmails2 = self.selectedMessage.to.replace(/\s*(,|^|$)\s*/g, '$1').split(',').filter((v, i, a) => a.indexOf(v) === i).filter(function(e) {return e !== self.selectedMessage.from});
      for (x in replyToEmails2) {
        replyToEmails.push(this.email_without_dot(replyToEmails2[x]));
      }
      replyToEmails = _.difference(replyToEmails, window.UserDashboard.currentUserFromEmails);
      replyToEmails = replyToEmails.join(', ');
    } else {
      replyToEmails = self.selectedMessage.from;
    }

    return replyToEmails;
  };

  this.email_without_dot = function(email) {
    var username;
    var email_provider;
    var updated_email = '';

    username = email.split('@')[0]
    email_provider = email.split('@')[1]

    // username = username.replace('.', '')

    updated_email = username.concat('@').concat(email_provider)
    return updated_email;
  }

  // Init CKEDITOR
  var editor;

  editor = CKEDITOR.replace('reply[description]', {
    language: I18n.currentLocale(),
    removePlugins: 'elementspath',
    resize_enabled: false
  });

  this.editor = editor;

  this.signature = ko.computed(function() {
    if(self.signatureSelected() != undefined) {
      let msgText = self.editor.getData().replaceAll('<br />', '<br>');
      if(self.lastSignature() != undefined) {
        msgText = msgText.replaceAll("<br><br>" + self.lastSignature().replace(/<br><br>$/,"<br>"), '');
      } else {
        self.loadAllServiceChannels().map(function(serviceChannel) {
          msgText = msgText.replaceAll("<br><br>" + serviceChannel.signature.replace(/<br><br>$/,"<br>"), '');
        });
      }

      self.messageText("<br>" + $('#reply_signature').val() + msgText);
      try {
        self.editor.setData(self.messageText());
      } catch(e) {}
    }
  });

  this.templateText.subscribe(function(newValue) {
    if(newValue != undefined) {
      let templateMessage = '\n' + newValue + '\n';
      self.editor.insertText(templateMessage);
      self.templateText('');
    }
  });

  this.addCompanyFile = function (file) {
    self.companyFiles.push(file);
  }

  this.removeCompanyFile = function () {
    self.companyFiles.remove(this);
  }
  this.showFilesModal = function () {
    window.userDashboardApp.viewModels.selectCompanyFilesModal.showModal({afterAddFile: self.addCompanyFile})
  }

  editor.on("change", function(evt) {
    $("#reply_text").val(evt.editor.getData());
  });

  editor.on('key', function () {
    self.task().isTextAdded = true;
   });

  new CKEDITOR.focusManager(editor).focus();
  // /CKEDITOR


  Views.BaseForm.call(this);
};

_.extend(Views.ReplyForm.prototype, new Views.BaseForm());
Views.ReplyForm.prototype.constructor = Views.ReplyForm;
