window.userDashboardService = {

  showStatusMessage: function (message, warning) {
    var container = $('div.alert');
    //var container = $('#alert-container');
    //console.log(container);
    //container.alert(message);
    container.find('div').html(message);

    if (warning) {
      container.removeClass('alert-success');
      container.addClass('alert-warning');
    } else {
      container.removeClass('alert-warning');
      container.addClass('alert-success');
    }

    container.show();
  },

  showStatusMessageInModal: function (message, warning) {
    var container = $('div.modal-alert');
    //var container = $('#alert-container');
    //console.log(container);
    //container.alert(message);
    container.find('div').html(message);

    if (warning) {
      container.removeClass('alert-success');
      container.addClass('alert-warning');
    } else {
      container.removeClass('alert-warning');
      container.addClass('alert-success');
    }

    container.show();
  },

  addNewMessage: function (data) {
    var agent_in_service_channel = false;
    // if(UserDashboard.current_user_service_channels.find(x => x.id === data.task.service_channel_id) === undefined && UserDashboard.currentUserId != data.task.assigned_to_user_id){
    //   agent_in_service_channel = true
    //   this.remoteDeletedTask(data);
    // }
    console.log("=============user_dashboard_service_Start==========")
    console.log(data)
    console.log("=============user_dashboard_service_end==========")

    if (data.task.deleted_at || data.task.state == 'archived') {
      this.remoteDeletedTask(data);
    } else {
      // Check if we have existing task and update it. if not, insert.
      var found = false;
      var foundTask;
      _.forEach(userDashboardApp.tasks().filter(function(v){return v!==''}), function (task) {
        console.log('*******==========task============*********')
        console.log(task)
        if (task.data.id == data.task.id) {
          // if(!userDashboardApp.availableToUser(task)) {
          //   userDashboardService.remoteDeletedTask(data);
          //   return false;
          // }

          if (data.message) {
            data.task.messages = [];
            data.task.messages.push(data.message);
          } else {
            data.task.messages = undefined;
          }
          task.updateTask(data.task);
          found = true;
          foundTask = task;

          // Someone else started to do this task. So hide it.
          if (userDashboardApp.selectedTask() == foundTask && !userDashboardApp.availableToUser(task)) {
            userDashboardApp.selectedTask(null);
          } else if (userDashboardApp.selectedTask() == foundTask && userDashboardApp.availableToUser(task)) {
            var tc = userDashboardApp.viewModels.taskContainer;
            if (!tc.showForwardForm() && !tc.showReplyForm() && !tc.showSmsForm()) {
              // Force the task view to update, there's probably a better way to do this with observables
              userDashboardApp.selectedTask(foundTask);
            }
          }
          return false;
        }
        return true;
      });

      if (!found) {
        if (data.task && data.message && !data.task.messages) {
          data.task.messages = [];
          data.task.messages.push(data.message);
        }
        foundTask = new Task(data.task);
        var fetch_index = [];
        var fetch_last_index = [];
        userDashboardApp.tasks().map((currElement, index) => {
          if((currElement.priorityClass().includes('priority-0') || currElement.priorityClass().includes("priority-no")) && (currElement.data.state == "new" || currElement.data.state == "open" || currElement.data.state == "waiting" || currElement.data.state == "ready")) {
            console.log("The current iteration is: " + index);
            fetch_index.push(index);
          }
          else{
            if(currElement.data.state != "new"){
              console.log("The current iteration is: " + index);
              fetch_last_index.unshift(index);
            }
          }
        });

        if(fetch_index.length > 0) {
          if(userDashboardApp.availableToUser(foundTask)) {
            userDashboardApp.tasks.splice( fetch_index[0], 0, foundTask);
          }
        } else {
          if(fetch_last_index.length > 0)
          {
            // if(userDashboardApp.availableToUser(foundTask)) {
              userDashboardApp.tasks.splice( fetch_last_index[0], 0, foundTask);
            // }
          }
          else{
            if(userDashboardApp.availableToUser(foundTask)) {
              userDashboardApp.tasks.unshift(foundTask);
            }
          }
        }
      }
      var isAddedNewMessage = (function () {
        if (data.message && found && data.task.state === 'open') return true;
      })();
      var isNewTask = data.task.state === 'new';
      var isAssignedToUser = (data.task.assigned_to_user_id === UserDashboard.currentUserId);
      if ((isNewTask || isAddedNewMessage) && data.message && !document.hasFocus() && userDashboardApp.availableToUser(new Task(data.task))) {
        userDashboardApp.viewModels.notifications.addNewTask(data);
      }

      userDashboardApp.resizeToFit();
    }

    // Should not need to reFilter if everything modified is observable?!
    // if(agent_in_service_channel){
    //   userDashboardApp.reFilter('test');
    // }else{
    //   userDashboardApp.reFilter();
    // }
    userDashboardApp.sortTasks();
  },

  remoteDeletedTask: function (data) {
    var foundTask = ko.utils.arrayFirst(userDashboardApp.tasks(), function (task) {
      return task.id == data.task.id;
    });
    userDashboardApp.tasks.remove(foundTask);

    if (userDashboardApp.selectedTask() == foundTask) {
      // Fixup for dialog overlay hanging around
      $('.modal.in').hide();
      $('body').removeClass('modal-open');
      $('.modal-backdrop').remove();

      if (data.task.state == 'archived') {
        foundTask.updateTask(data.task);
      } else {
        userDashboardApp.selectedTask(null);
      }
    }
  },

  alertWaitingTaskTimeout: function (data) {
    var foundTask = ko.utils.arrayFirst(userDashboardApp.tasks(), function (task) {
      return task.id == data.task.id;
    });

    if (!foundTask || foundTask.assigned_to_user_id() != UserDashboard.currentUserId) {
      return;
    }

    if ((!foundTask.alerted_at || (foundTask.alerted_at && moment().diff(moment(foundTask.alerted_at), "minutes") > 5)) && foundTask.data.media_channel == 'call') {
      console.log("foundTask..... ",foundTask)
      if(document.getElementById(foundTask.id)){
        var el = document.getElementById(foundTask.id).closest(".bootbox").getElementsByClassName('bootbox-close-button');

        for (var i=0;i<el.length; i++) {
          el[i].click();
        }
      }
      var dialogMessage = $('<div>');
      var template = JST['templates/tasks/waiting_task_timeout_alert'];

      dialogMessage.html(template({
        task: ko.toJS(foundTask.data),
        message: ko.toJS(foundTask.lastMessage().data),
        firstMessage: ko.toJS(foundTask.firstMessage().data),
        iconClass: foundTask.iconClass
      }));
      dialogMessage.find('.row').attr('id', foundTask.id);
      dialogMessage.find('#task-list-item-create-time').text(foundTask.createdAt)
      bootbox.dialog({
        title: I18n.t('user_dashboard.waiting_time_out_modal_title'),
        message: dialogMessage.html(),
        buttons: {
          cancel: {
            label: I18n.t('user_dashboard.keep_working'),
            className: 'btn-default',
            callback: function () {
              foundTask.refreshWaitingTimeout();
            }
          },
          success: {
            label: I18n.t('user_dashboard.ok'),
            className: 'btn-default',
            callback: function () {
              foundTask.changeStateEvent('renew', false, null);
            }
          }
        }
      });
      foundTask.alerted_at = new Date();
    }
  },

  ajaxFailed: function (response) {
    if (response.status == 405) {
      // http://js2.coffee
      var blah, ref;
      blah = ((ref = response.responseJSON) !== null ? ref.already_in_use_by : void 0) ? I18n.t('user_dashboard.task_is_already_in_work') : "You cannot do this action";

      bootbox.alert(blah);
    }
  }

};
