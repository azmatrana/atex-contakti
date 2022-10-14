

Views.BaseForm = function(params) {

  var self = this;

  this.templateForStateModal = JST['templates/tasks/message_buttons_confirmation'];

  this.attributes = ko.observable({
    action: ko.pureComputed(function() {
      if(typeof UserDashboard !== 'undefined') {
        return '/' + UserDashboard.locale + '/tasks/' + self.task().id + '.js';
      }
    }),
    method: 'PUT',
    formMethod: 'POST',
    'data-remote': true
  });

  this.addAttachment = function(obj, e) {
    var clone = $(e.currentTarget).siblings('.fileupload.template').clone();
    var fileField = clone.find(".file-field");
    fileField.attr('name', fileField.attr('name').replace(/(.*\[)0(\]\[file\])/, "$1"+new Date().getTime()+"$2"));
    $(e.currentTarget).closest('.fileupload-section').append(clone.removeClass('hidden template').addClass('attachments'));
  };

  this.sendForm = function(data, event) {
    // Should not show stateChangeModal for SMS? Atleast the test say so.
    if(!(self instanceof Views.SmsForm) || self.task().data.media_channel === 'sms') {
      self.showStateChangeModal();
    }

    if(self instanceof Views.ReplyForm) {
      var message;
      if(self.internal()) {
        message = self.task().firstMessage();
      } else {
        message = self.task().firstNotInternalNotSmsMessage();

        if(!message) {
          message = self.task().firstMessage();
        }
      }
      var channel_name = message.data.channel_type
      message = message.formattedDescription();
      // if(channel_name == "email"){
        var pos = message.indexOf("[Task ID");
        message = message.substring(pos);
      // }
      // self.editor.setData(self.editor.getData() + '<br><br>' + message);
      $("#reply_text").val(self.editor.getData() + '<br><br>' + message);
    }
    var form = $(event.target).closest('form');
    var formData = new FormData(form[0]);
    /*form.trigger('submit.rails');*/

    self.showFormObservable(false);

    $.ajax({
      url: form.attr('action'),
      method: form.attr('method'),
      data: formData,
      contentType: false,
      cache: false,
      processData: false,
      success: function() {
      },
      error: function() {
        userDashboardService.showStatusMessage(I18n.t('user_dashboard.invalid_service_channel'), true);
      }
    });
  };

  this.showForm = function() {
    self.showFormObservable(true);
  };

  this.cancelClicked = function() {
    self.task().saveDraft();
    self.task().renew();
    self.showFormObservable(false);

    if(self.cancelCallback) {
      self.cancelCallback();
    }
  };

  this.showStateChangeModal = function() {
    var dialogMessage;

    dialogMessage = $('<div>');
    var taskJSON = ko.toJS(self.task());
    dialogMessage.html(self.templateForStateModal({
      task: taskJSON
    }));

    $(dialogMessage).find('input[name="event"]:first').attr('checked', true);
    bootbox.dialog({
      title: I18n.t('user_dashboard.select_state_for_this_task'),
      message: dialogMessage.html(),
      buttons: {
        cancel: {
          label: I18n.t('user_dashboard.cancel'),
          className: 'btn-default'
        },
        success: {
          label: I18n.t('user_dashboard.save'),
          className: 'btn-default',
          callback: function(event) {
            var form, state, callback;
            form = $('#task-buttons-confirmation-form');
            state = form.find('input[name="event"]:checked').val();
            if (state === 'close') {
              callback = function () {
                window.userDashboardApp.viewModels.taskContainer.closeTaskClicked();
              };
            }
            this.changeStateEvent(state, null, callback);
          }.bind(self.task())
        }
      }
    });

  };

};
