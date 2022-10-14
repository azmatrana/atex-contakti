
Views.ForwardForm = function(params) {

  var self = this;

  this.task = params.task;
  this.showFormObservable = params.showForm;
  this.selectedMessage = this.task().firstNotSmsMessage();
  this.signatureSelected = ko.observable();
  this.emailsCcField = ko.observable('');
  this.emailsBccField = ko.observable('');
  this.serviceChannels = ko.observableArray([]);
  this.agentServiceChannels = ko.observableArray([]);
  this.signatures = ko.observableArray([]);
  this.signature = ko.computed(function() {
      var currentSignature = self.signatureSelected;
      if(typeof(editor) !== "undefined") {
        editor.setData("<br><br>" + currentSignature);
      }
    });
  this.all_service_channels_query_url = "tasks/get_all_service_channels";
  this.messageText = ko.observable('');
  this.cancelCallback = params.cancelCallback;

  if(window.userSignature) {
    this.messageText(this.messageText() + "<br><br>" + window.userSignature);
  }

  function ServiceChannelResult(data) {
    var self = this;
    this.id = data[0];
    this.name = data[1];
    this.signature = data[2];
  }


  this.make_chain = function(message) {
    var whole_msg = message.formattedDescription();
    var from = message.from === undefined ? '' : message.from.replace('<', '').replace('>', '');
    return "<br/><br/>" + from + ' ' + moment(message.createdAt).format('DD.MM.YYYY HH:mm') + " wrote: <br/><br/> " + whole_msg;
  };

  this.loadAllServiceChannels = function () {
    if ( self.serviceChannels().length > 0 ) // Return if service channels already retrieved
      return;

    $.ajax({
      url: self.all_service_channels_query_url,
      dataType: 'json',
      success: function (data) {
        self.serviceChannels([]);
        self.agentServiceChannels([]);
        _.forEach(data, function (res, key) {
          self.serviceChannels.push(new ServiceChannelResult([res[0], I18n.t('user_dashboard.user_dashboard_mailer.service_channel') + ": " + res[1]]));
          self.agentServiceChannels.push(new ServiceChannelResult([res[0], I18n.t('user_dashboard.user_dashboard_mailer.service_channel') + ": " + res[1]]));
          if(res[2]) {
            self.signatures.push(new ServiceChannelResult([res[0], I18n.t('user_dashboard.user_dashboard_mailer.service_channel') + ": " + res[1], res[2]]));
          }
        });
        self.serviceChannels.sort(function (left, right) {
          return left.name.toLowerCase() == right.name.toLowerCase()
            ? 0
            : (left.name.toLowerCase() < right.name.toLowerCase() ? -1 : 1);
        });
        self.agentServiceChannels.sort(function (left, right) {
          return left.name.toLowerCase() == right.name.toLowerCase()
            ? 0
            : (left.name.toLowerCase() < right.name.toLowerCase() ? -1 : 1);
        });
        if (window.hasPersonalEmail || true) {
          self.serviceChannels.push(new ServiceChannelResult(['agent', I18n.t('user_dashboard.user_dashboard_mailer.agent')]));
        }
        if (window.userSignature) {
          self.signatures.push(new ServiceChannelResult(['agent', I18n.t('user_dashboard.user_dashboard_mailer.agent'), window.userSignature]));
          self.signatureSelected = window.userSignature;
        }
      }
    });
  };


  var msg = this.make_chain(this.selectedMessage);
  this.messageText(msg);

  // Init CKEDITOR
  var editor;

  editor = CKEDITOR.replace('reply[description]', {
    language: I18n.currentLocale(),
    removePlugins: 'elementspath',
    resize_enabled: false
  });

  editor.on("change", function(evt) {
    $("#forward-description").val(evt.editor.getData());
  });

  $('#send_email_signature_forward').on("change", function() {
      editor.insertHtml($(this).val())
  });

  self.loadAllServiceChannels();

  new CKEDITOR.focusManager(editor).focus();
  // /CKEDITOR

  Views.BaseForm.call(this);
};

_.extend(Views.ForwardForm.prototype, new Views.BaseForm());
Views.ForwardForm.prototype.constructor = Views.ForwardForm;
