define([
  "jquery",
  "plugins/router",
  "durandal/app",
  "knockout",
  "api",
  "appdata",
  "i18next",
  "moment",
  "models/task",
  "models/email",
  "bootstrap/collapse",
  "bootstrap/modal"
], function ($,
             router,
             app,
             ko,
             api,
             appdata,
             i18n,
             moment,
             Task,
             Email) {
  var self;

  self = {
    router: router,
    applicationOffline: ko.observable(false),
    newTask: ko.observable(null),
    newEmail: ko.observable(null),
    menuEnabled: ko.observable(false),
    isNewItemActive: ko.observable(false),
    isNewTaskComplete: ko.observable(false),
    isNewEmailComplete: ko.observable(false),
    isNewEmailSending: ko.observable(false),
    serviceChannels: ko.observableArray([]),
    emailServiceChannels: ko.observableArray([]),
    serviceChannelAgents: ko.observableArray([]),
    availableAgents: ko.observableArray([]),
    activate: function () {
      appdata.runAfterDataLoaded(function () {
        ko.utils.arrayPushAll(self.serviceChannels, appdata.getServiceChannels());
        ko.utils.arrayPushAll(self.emailServiceChannels, appdata.getEmailServiceChannels());
      });

      // Handlers for signaling. These signals are broadcast from other parts
      // by app.trigger()
      app.on("menu:toggle").then(function (enable) {
        self.menuEnabled(enable);
      });

      app.on('navbar:hide').then(function () {
        if ($('#contakti-navbar-collapse').css('display') !== 'none') {
          $('.navbar-toggle').trigger('click');
        }
      });

      app.on('api:offline').then(function () {
        $(".modal").modal("hide");
        self.applicationOffline(true);
      });

      $('#new-item-modal').on('hidden.bs.modal', function () {
        self.isNewItemActive(false);
        self.newEmail(null);
      });

      router.map([
        {route: "", title: i18n.t("app:login.sign_in"), moduleId: "viewmodels/login"},
        {route: "tasks(/:id)", title: i18n.t("app:task.tasks"), moduleId: "viewmodels/tasks", nav: true}
        //{ route: "tasks/:id", title: "Task Details", moduleId: "viewmodels/task" }
      ]).buildNavigationModel();

      return router.activate();
    },
    onReconnectClicked: function () {
      var self = this;
      api.checkSession().success(function (xhr) {
        self.applicationOffline(false);
        router.navigate("tasks", {replace: true, trigger: true});
      }).error(function (xhr) {
        if (xhr.status === 401) {
          self.applicationOffline(false);
          router.navigate("", {replace: true, trigger: true});
        }
      });
    },
    onSignOutClicked: function () {
      api.resetSession();
      console.log('logouted');
      app.trigger("session:reset");
      app.trigger("navbar:hide");
      router.navigate("/", {replace: true, trigger: true});
      return false;
    },
    // Below called, when '+' clicked in UI
    onNewItemClicked: function () {
      this.isNewItemActive(true);
      $('#new-item-modal').modal('show');
    },

    // Below called, when user has clicked 'Task' button (for creating new one)
    onNewTaskClick: function () {
      var task = new Task({
        format_time_till_red_alert: '',
        messages: [{title: '', description: ''}]
      });
      var message = task.messages()[0];

      var self = this;
      message.title.subscribe(function () {
        self._checkTaskComplete();
      });
      message.description.subscribe(function () {
        self._checkTaskComplete();
      });

      // Clears the Service channel list initially
      this.serviceChannelAgents([]);
      task.service_channel_id.subscribe(function (newId) {
        self._checkTaskComplete();
        // Assume unique id's for item, thus can rely on arrayFirst
        var sc = ko.utils.arrayFirst(self.serviceChannels(), function (item) {
          return item.id == newId
        });
        if (sc) {
          // We have a task, get agents
          self.serviceChannelAgents(sc.agents);
        } else {
          // No task, then the agents list is empty?
          self.serviceChannelAgents([]);
        }
      });

      this.newTask(task);
      $('#new-task-modal').one('hidden.bs.modal', function () {
        self.newTask(null);
        self.isNewTaskComplete(false);
      }).one('shown.bs.modal', function () {
        $('#new-item-modal').modal('hide');
      }).modal('show');
    },
    onCancelNewTask: function () {
      $('#new-task-modal').modal('hide');
      this.isNewTaskComplete(false);
      this.newTask(null);
    },
    // onConfirmNewTask: function () {
    //   var self = this;
    //   this.newTask().create().done(function () {
    //     self.onCancelNewTask();
    //   });
    // },
    onConfirmNewTask: function (data, event) {
      // target event 
      var $target = $(event.target);
      var form = $target.closest('form');
      var formData = new FormData(form[0]);
      // formData
      formData.set('language', i18n.lng());
      $target.prop('disabled', true);
      // this.isNewEmailSending(true);
      api.post('/tasks', formData).done(function () {
         self.onCancelNewTask();
      });
    },
    onNewEmailClick: function () {
      var email = new Email({
        language: i18n.lng(),
        recipient: '',
        serviceChannelId: 'agent',
        cc: '',
        bcc: '',
        subject: '',
        message: ''
      });

      var self = this;
      email.recipient.subscribe(function () {
        self._checkEmailComplete();
      });
      email.subject.subscribe(function () {
        self._checkEmailComplete();
      });
      email.message.subscribe(function () {
        self._checkEmailComplete();
      });

      this.newEmail(email);
      $('#new-email-modal').one('hidden.bs.modal', function () {
        self.newEmail(null);
        self.isNewEmailComplete(false);
      }).one('shown.bs.modal', function () {
        $('#new-item-modal').modal('hide');
      }).modal('show');
    },
    onCancelNewEmail: function () {
      $('#new-email-modal').modal('hide');
      this.isNewEmailComplete(false);
      this.newEmail(null);
    },
    onConfirmNewEmail: function (data, event) {
      var $target = $(event.target);
      var form = $target.closest('form');
      var formData = new FormData(form[0]);
      formData.set('language', i18n.lng());
      $target.prop('disabled', true);
      this.isNewEmailSending(true);
      api.post('/tasks/send_email', formData).done(function () {
        self.isNewEmailSending(false);
        $target.prop('disabled', false);
        self.onCancelNewEmail();
      });
    },
    showNewEmailSubmitBut: function () {
      if (this.isNewEmailComplete() && !this.isNewEmailSending()) {
        return true;
      } else {
        return false;
      }
    },
    _checkTaskComplete: function () {
      this.isNewTaskComplete(false);

      var message = this.newTask().messages()[0];
      if (message.title().trim().length == 0) {
        return false;
      }
      if (message.description().trim().length == 0) {
        return false;
      }
      if (this.newTask().service_channel_id() < 1) {
        return false;
      }

      this.isNewTaskComplete(true);
      return true;
    },
    _checkEmailComplete: function () {
      this.isNewEmailComplete(false);

      var email = this.newEmail();
      if (email.recipient().trim().length == 0) {
        return false;
      }
      if (email.subject().trim().length == 0) {
        return false;
      }
      if (email.message().trim().length == 0) {
        return false;
      }

      this.isNewEmailComplete(true);
      return true;
    },
    addAttachment: function(obj, e) {
      var clone = $(e.currentTarget).siblings('.fileupload.template').clone();
      var fileField = clone.find(".file-field");
      fileField.prop('disabled', false);
      fileField.attr('name', fileField.attr('name').replace(/(.*\[)0(\]\[file\])/, "$1"+new Date().getTime()+"$2"));
      $(e.currentTarget).closest('.fileupload-section').append(clone.removeClass('hidden template').addClass('attachments'));
    }
  };
  return self;
});
