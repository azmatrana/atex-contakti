

Views.TaskList = function(tasks) {

    var self = this;
    this.tasks = tasks;
    this.callbacks = {
        openTask: [
          function(task) {
            $('#task-list-panel-container').addClass('hidden-xs');
            $('#task-panel-container').show();
          }
        ]
    };

    this.taskClicked = function(task) {
        _.forEach(self.callbacks.openTask, function(func) {
            func(task);
        });

        userDashboardApp.resizeToFit();
    };

    return this;
};

Views.TaskList.prototype = Views;
