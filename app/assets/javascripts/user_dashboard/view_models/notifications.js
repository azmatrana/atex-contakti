Views.Notifications = function() {
  var self = this;
  this.count = ko.observable(0);

  this.addNewTask = function(data) {
    if(userDashboardApp.DesktopNotifications) {
      var bodyMessage = I18n.t('service_channels.service_channel_title') + ": " + data.task.service_channel.name + "  \n";
      bodyMessage += I18n.t('reports.index.media_channel') + ": " + I18n.t('users.agents.media_channel_types.' + data.task.media_channel);
      notify.createNotification(I18n.t('user_dashboard.new_task'), {body: bodyMessage, icon: "notification.png"});
    }

    this.count(this.count() + 1);
  };

  this.clearTasks = function() {
    self.count(0);
  };
};


Views.Notifications.prototype = Views;

