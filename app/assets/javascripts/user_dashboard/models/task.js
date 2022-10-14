function Task(data) {
  var self = this;
  this.id            = data.id;
  this.data          = data;
  this.state         = ko.observable(data.state);
  this.priorityClass = ko.observable(' priority-no');

  this.messages      = ko.observableArray();
  this.skills        = ko.observableArray();
  this.flags         = ko.observableArray();
  this.generic_tags  = ko.observableArray();

  this.selected = ko.observable(false);

  this.serviceChannelId    = ko.observable(this.data.service_channel.id);
  this.serviceChannelName  = ko.observable(this.data.service_channel.name);
  this.assigned_to_user_id = ko.observable(this.data.assigned_to_user_id);
  this.recieverNumber      = ko.observable(this.data.messages[0].to)

  this.isUrgent = ko.observable(false);
  this.isSpam   = ko.observable(false);
  this.follow_user_ids = ko.observableArray(this.data.follow_user_ids);

  this.noteBody = ko.observable(this.data.note_body);
  this.showNote = function() {
    return this.data.note_body;
  };

  this.may_close   = ko.observable(this.data.may_close);
  this.may_lock    = ko.observable(this.data.may_lock);
  this.may_pause   = ko.observable(this.data.may_pause);
  this.may_renew   = ko.observable(this.data.may_renew);
  this.may_restart = ko.observable(this.data.may_restart);
  this.may_start   = ko.observable(this.data.may_start);
  this.may_unlock  = ko.observable(this.data.may_unlock);
  this.call_counter = ko.observable(data.call_counter);
  this.order_id    = ko.observable(data.order_id);
  this.missingSmsCounter = ko.observable(this.data.data.missing_sms_counter);
  this.showMessagesList = ko.observable(false);
  this.isTextAdded = false;

  this.closedByUserFullName = ko.pureComputed(function() {
    if (!self.showClosedByUser()) return;
    return self.data.closed_by_user.first_name + ' ' + self.data.closed_by_user.last_name;
  });

  this.sendByUserFullName = ko.pureComputed(function() {
    if (!self.showSendByUser()) return;
    return self.data.send_by_user.first_name + ' ' + self.data.send_by_user.last_name;
  });

  this.showClosedByUser = ko.pureComputed(function() {
    return self.state() === 'ready' && self.data.closed_by_user;
  });

  this.showSendByUser = ko.pureComputed(function() {
    return self.data.send_by_user;
  });

  this.agent = ko.observable(this.data.agent);
  this.agentName = ko.pureComputed(function() {
    if (!self.agent()) return;
    return self.agent().first_name + ' ' + self.agent().last_name;
  });

  switch (data.media_channel) {
    case 'call':
      this.iconClass = ' glyphicon-earphone';
      break;
    case 'web_form':
      this.iconClass = ' glyphicon-globe';
      break;
    case 'email':
      this.iconClass = ' glyphicon-envelope';
      break;
    case 'chat':
      this.iconClass = ' glyphicon-comment';
      break;
    case 'internal':
      this.iconClass = ' glyphicon-tag';
      break;
    case 'sms':
      this.iconClass = ' glyphicon-send';
      break;
    default:
      this.iconClass = ' glyphicon-question-sign';
  };
/*
*/

  this.getPriorityClass = function () {
    var priorityCssClass;
    switch (this.data.priority) {
      case 0:
        priorityCssClass = ' priority-0';
        break;
      case 1:
        priorityCssClass = ' priority-1';
        break;
      case 2:
        priorityCssClass = ' priority-2';
        break;
      case 3:
        priorityCssClass = ' priority-3';
        break;
      default:
        priorityCssClass = 'priority-no';
    };
    return priorityCssClass;
  };

  this.priorityClass(this.getPriorityClass());

  this.toggleMessagesList = function () {
    self.showMessagesList(!self.showMessagesList());
  };

  this.firstNotInternalMessage = function () {
    return ko.utils.arrayFirst(self.messages(), function(mess) {
      return !mess.isInternal();
    });
  };

  this.sortedMessages = function () {
    var messages = self.messages().slice();
    messages.sort(function (a, b) {
      return b.data.number - a.data.number;
    });
    return messages;
  };

  this.firstNotInternalNotSmsMessage = function () {
    return ko.utils.arrayFirst(this.sortedMessages(), function(mess) {
      return !mess.isInternal() && !mess.data.sms;
    });
  };

  this.firstNotSmsMessage = function () {
    return ko.utils.arrayFirst(this.sortedMessages(), function(mess) {
      return !mess.data.sms;
    });
  };

  this.itemStatusState = ko.pureComputed(function() {
    return ' item-status-' + self.state() + ' ' +
      (self.data.media_channel == 'call' ? 'phone' : 'email');
  });


  this.cssType = ko.pureComputed(function() {
    return (self.data.media_channel == 'call' || self.data.media_channel == 'sip') ?
      'phone' : 'email';
  });

  this.formatCountDownTime = function() {
    return moment.duration(data.minutes_till_red_alert, "minutes").humanize(true);
  };

  this.getClockClass = function() {
    if (data.minutes_till_red_alert <= 0) {
      return 'status-urgent';
    } else if (data.minutes_till_yellow_alert <= 0) {
      return 'status-warning';
    } else {
      return 'status-ok';
    }
  };


  this.urgentCss = ko.observable('');

  this.timer      = ko.observable(this.formatCountDownTime());
  this.clockClass = ko.observable(this.getClockClass());

  this.messagesFetched = false;
  this.messagesSorting = false;

  this.sortMessages = function() {
    if (!self.messagesSorting) {
      self.messagesSorting = true;
      self.messages.sort(function (a, b) {
        return moment(a.createdAt).isBefore(moment(b.createdAt));
      });
      self.messagesSorting = false;
    }
  };


  this.hasUnReadMessages= function(){
    var unReadMessage = false
    if (self.messages() && self.messages().length > 0) {
      self.messages().forEach((message) => {
        if (message.data.marked_as_read === false) {
          unReadMessage = true;
        }
      })
    }
    return unReadMessage;
  }


  this.messagesUpdated = false;

  this.sendMarkAsRead = function(){
    if (self.hasUnReadMessages() === true){
      $.ajax({
        url: '/tasks/' + self.id + '/mark_message_as_read',
        dataType: 'json',
        method: 'get',
        success: function (data) {
          console.log("message marked as read");
          self.messagesUpdated = false;
        }
      })
    }
  }

  this.markAsRead = function(){
    if (window.userDashboardApp.selectedTask()!== null && self.id === window.userDashboardApp.selectedTask().id && $('#task-panel-container').is(":visible")){
      self.sendMarkAsRead()
    }
    else {
      self.messagesUpdated = true;
    }
  }

  // Sort when even single item is changed
  this.messages.subscribe(this.sortMessages, null, "arrayChange");
  this.messages.subscribe(this.markAsRead, null, "arrayChange");

  // And sort when whole observableArray replaced
  this.messages.subscribe(this.sortMessages);

  this.isUrgent.subscribe(function() {
    if(self.isUrgent()) {
      self.urgentCss('urgent');
    } else {
      self.urgentCss('');
    }
  });

  this.buildArray = function(dataSource, objClass) {
    var tempArray = new Array();
    _.forEach(dataSource, function(item) {
      tempArray.push(new objClass(item, self));
    });
    return tempArray;
  };

  this.messages(this.buildArray(data.messages, TaskMessage));
  this.skills(this.buildArray(data.skills, Skill));
  this.flags(this.buildArray(data.flags, Flag));
  this.generic_tags(this.buildArray(data.generic_tags, GenericTag));

  this.setUrgent   = function() { self.createFlag('urgent'); }
  this.unsetUrgent = function() { self.removeFlag('urgent'); }
  this.setSpam     = function() { self.createFlag('spam'); }

  this.createFlag = function(flag_name) {
    var new_flag = new Flag(flag_name, self);
    new_flag.save();
  };

  this.removeFlag = function(flag_name) {
    _.forEach(self.flags(), function(flag) {
      if(flag.name == flag_name) {
        flag.destroy();
      }
    });
  };

  //this.redAlertTimeInDecimal = ko.pureComputed(function () {
  this.redAlertTimeInDecimal = function () {
    //var originalMinutes = data.format_time_till_red_alert;
    var originalMinutes;
    if (data.minutes_till_red_alert < 0) originalMinutes = data.minutes_till_red_alert;
    else originalMinutes = data.minutes_till_yellow_alert;

    var momentDuration = moment.duration(Math.abs(originalMinutes), "minutes");
    var characterBeforeTime = data.minutes_till_red_alert < 0 ? "+" : "";
    var toFixedValue = 2;

    if (momentDuration.asYears() >= 1)
      return characterBeforeTime + momentDuration.asYears().toFixed(toFixedValue) + "y";
    else if (momentDuration.asMonths() >= 1)
      return characterBeforeTime + momentDuration.asMonths().toFixed(toFixedValue) + "m";
    else if (momentDuration.asWeeks() >= 1)
      return characterBeforeTime + momentDuration.asWeeks().toFixed(toFixedValue) + "w";
    else if (momentDuration.asDays() >= 1)
      return characterBeforeTime + momentDuration.asDays().toFixed(toFixedValue) + "d";
    else if (momentDuration.asHours() >= 1)
      return characterBeforeTime + momentDuration.asHours().toFixed(toFixedValue) + "h";

    return characterBeforeTime + momentDuration.asMinutes().toFixed(toFixedValue) + "min";
  };

  this.stopLoop = function() {
    if (typeof self.loop != 'undefined') {
      clearInterval(self.loop);
    }
  };

  this.loop = setInterval(function() {
    data.minutes_till_red_alert = data.minutes_till_red_alert - 1;
    data.minutes_till_yellow_alert = data.minutes_till_yellow_alert - 1;
    self.clockClass(self.getClockClass());
    self.timer(self.formatCountDownTime());
  }, 60*1000);



  this.onOpen = function() {
    if (self.messagesUpdated === true){
      self.sendMarkAsRead();
    }

    if(self.messagesFetched) return;

    $.ajax({
      url: '/tasks/' + self.id + '/messages',
      dataType: 'json',
      method: 'get',
      success: function(data) {
        _.forEach(data, function(message) {
          var elem = ko.utils.arrayFirst(self.messages(), function(mess) {
            return mess.id === message.id;
          });
          if(elem) {
            elem.formatted_description(message.formatted_description);
            elem.attachments(message.attachments);
            elem.messageFetched(true);
          } else {
            self.messages.push(new TaskMessage(message, self));
          }
        });
        self.data.messages = data;
        console.log(data);
        self.messagesFetched = true;
      }
    });
  };

  this.createdAt = moment(this.data.created_at).format('DD.MM.YYYY HH:mm');

  this.messageSubject = ko.pureComputed( function() {
      var lastSubject = 'SMS';
      self.messages().forEach(function(message) {
        if (message.title && message.title.length > 0) {
          lastSubject = message.title;
        }
      });

      return lastSubject;
  });

  this.isCallback = ko.pureComputed( function() {
    var lastSubject = 'unanswered_call';
    self.messages().forEach(function(message) {
      if (message.title && message.title.length > 0) {
        if(message.channel_type === 'call'){
          lastSubject = [message.title.split(' ')[0], message.title.split(' ')[1]].join('_').toLowerCase();
        } else {
          lastSubject = message.title
        }
      }
    });

    if(lastSubject === 'unanswered_call') {
      return true;
    } else {
      return false;
    }
  });

  this.messageTitle = ko.pureComputed( function() { return self.messages()[0].title;});
  this.lastMessage  = ko.pureComputed( function() { return self.messages()[self.messages().length - 1];});
  this.firstMessage = ko.pureComputed( function() { return self.messages()[0];});

  this.notCallnotSmsFrom = ko.pureComputed(function() {
    if (self.data.media_channel === 'chat') {
      if (self.data.customer) {
        return self.data.customer.contact_email || self.data.customer.first_name || self.data.customer.name
      } else if (self.lastMessage().data.from === 'Anonymous') {
        return self.lastMessage().to;
      } else {
        return self.lastMessage().from;
      }
    } else {
      return self.lastMessage().from;
    }
  });

  this.contactTo = function() {
    if(typeof self.messages()[0] === 'undefined') {
      return '';
    }
    if(self.messages()[0].channel_type == 'call' || self.messages()[0].channel_type == 'sip') {
      return 'tel:' + self.messages()[0].from;
    } else {
      return 'mailto:' + self.messages()[0].from;
    }
  };

  this.lastMessageCreatedAt = ko.pureComputed( function() {
    if(typeof self.lastMessage() != 'undefined') {
      return moment(self.lastMessage().createdAt).format('DD.MM.YYYY HH:mm');
    } else {
      return '';
    }
  });

  this.redAlertFormatted = ko.pureComputed( function() {
    return moment(self.data.red_alert_or_ready_date).format('DD.MM.YYYY HH:mm');
  } );

  this.scheduled = ko.pureComputed( function() {
    return (!self.data.has_schedule || self.data.has_time_in_schedule);
  } );

  this.combinedMessages = ko.computed(function() {
    return ko.utils.arrayFilter(self.messages(), function(message) {
      if(!message.data) {
        return false;
      }
      return true;
    }).sort(function (left, right) {
      return moment.utc(right.createdAt).diff(moment.utc(left.createdAt))
    });;
  });

  this.internalMessages = ko.computed(function() {
    return ko.utils.arrayFilter(self.messages(), function(message) {
      if(!message.data) {
        return false;
      }
      if(message.data.is_internal) {
        return true;
      }
      return false;
    });
  });

  this.externalMessages = ko.computed(function() {
    return ko.utils.arrayFilter(self.messages(), function(message) {
      if(message.data && message.data.is_internal) {
        return false;
      }
      return true;
    });
  });

  this.updateTask = function(newTaskData) {
    // TODO: What else might mutate?
    this.state(newTaskData.state);
    if(newTaskData.state === 'ready' && newTaskData.closed_by_user){
      self.data.closed_by_user = newTaskData.closed_by_user
    }
    if(newTaskData.state === "ready") {
      this.stopLoop();
    }
    this.serviceChannelId(newTaskData.service_channel.id);
    this.serviceChannelName(newTaskData.service_channel.name);
    if(newTaskData.hasOwnProperty('note_body')) {
      this.noteBody(newTaskData.note_body);
    }

    this.may_close(newTaskData.may_close);
    this.may_lock(newTaskData.may_lock);
    this.may_pause(newTaskData.may_pause);
    this.may_renew(newTaskData.may_renew);
    this.may_restart(newTaskData.may_restart);
    this.may_start(newTaskData.may_start);
    this.may_unlock(newTaskData.may_unlock);
    this.assigned_to_user_id(newTaskData.assigned_to_user_id);
    this.call_counter(newTaskData.call_counter);
    this.missingSmsCounter(newTaskData.data.missing_sms_counter);
    this.follow_user_ids(this.data.follow_user_ids);
    this.agent(newTaskData.agent);
    this.order_id(newTaskData.order_id);

    if(newTaskData.messages && newTaskData.messages.length > 0) {
      _.forEach(newTaskData.messages, function(message) {
        var elem = ko.utils.arrayFirst(self.messages(), function(mess) {
          return mess.id === message.id;
        });
        if(elem) {
          elem.formatted_description(message.formatted_description);
          elem.call_transcript(message.call_transcript);
        } else {
          self.messages.unshift(new TaskMessage(message, self));
        }
      });
    }

    this.data = newTaskData;
    this.priorityClass(this.getPriorityClass());

    if(newTaskData.skills) {
      self.skills(self.buildArray(newTaskData.skills, Skill));
    }
    if(newTaskData.flags) {
      self.flags(self.buildArray(newTaskData.flags, Flag));
    }
    if(newTaskData.generic_tags) {
      self.generic_tags(self.buildArray(newTaskData.generic_tags, GenericTag));
    }

    this.isUrgent(_.contains(_.pluck(self.flags(), 'name'), 'urgent'));
  };

  this.follow = function() {
    self.followTask();
  };

  this.unfollow = function() {
    self.unfollowTask();
  };

  this.lock = function() {
    self.changeStateEvent('lock');
  };

  this.unlock = function() {
    self.changeStateEvent('unlock');
  };

  this.archive = function() {
    self.changeStateEvent('archive');
  };

  this.close = function(result) {
    var callback = function () {
      window.userDashboardApp.viewModels.taskContainer.closeTaskClicked();
    };
    self.changeStateEvent('close', result, callback);
  };

  this.start = function() {
    self.changeStateEvent('start');
  };

  this.restart = function() {
    self.changeStateEvent('restart');
  };

  this.pause = function() {
    self.changeStateEvent('pause');
  };

  this.markAsNew = function() {
    self.changeStateEvent('new');
  };

  this.renew = function() {
    self.changeStateEvent('renew');
  };

  this.saveDraft = function() {
    if (self.isTextAdded === true) {
      var data = {description: $('#reply_text').val()};
      $.ajax({
        url: '/tasks/' + self.id + '/save_draft',
        method: 'POST',
        data: data
      });
      self.isTextAdded = false;
    }
  };

  this.delete = function() {
    $.ajax({
      url: '/tasks/' + self.id,
      method: 'DELETE',
      dataType: 'json',
      fail: function() {
        alert("Failed to delete the task!");
      }
    });
  };

  this.followTask = function() {
    $.ajax({
      url: '/tasks/' + self.id + '/follow_task',
      method: 'POST',
      success: function(updatedTask) {
        self.updateTask(updatedTask);
      }
    });
  };

  this.unfollowTask = function() {
    $.ajax({
      url: '/tasks/' + self.id + '/unfollow_task',
      method: 'POST',
      success: function(updatedTask) {
        self.updateTask(updatedTask);
      }
    });
  };

  this.changeStateEvent = function(newState, sendResult, callback) {
    var data = { event: newState };
    if(sendResult) {
      data.result = sendResult;
    }
    $.ajax({
      url: '/tasks/' + self.id + '/change_state',
      method: 'POST',
      data: data,
      success: function(updatedTask) {
        // self.updateTask(updatedTask);
        // Do nothing as danthes publishes the task?
        //        @set(@parse(updatedTask))
        //callback() if callback
        console.log("TASK WAS UPDATED");
        console.log(updatedTask);
        if(callback) {
          callback();
        }
      },
      fail: function(response) {
        if(response.status == 405) {
          var message;
          if(response.responseJSON && response.responseJSON.task) {
            message = I18n.t('user_dashboard.task_is_already_in_work', {agent: self.data.agent.first_name + ' ' + self.data.agent.last_name});
          } else {
            message = 'You cannot do this action';
          }
          bootbox.alert(message, function() {
            // ??? Setting the tasks.errors variable?
          });
        }
        //if response.status == 405
        //  message = if response.responseJSON?.task
        //              task = response.responseJSON.task
        //              I18n.t('user_dashboard.task_is_already_in_work', {agent: "#{task.agent.first_name} #{task.agent.last_name}"})
        //            else
        //              "You cannot do this action"
        //  bootbox.alert(message, =>
        //    @set(@parse(response.responseJSON?.task)) if task
        //  )

      }
    });

  };

  this.tagsAsString = ko.pureComputed(function() {
    var tags=[];
    _.forEach(self.skills(), function(tag) {
      tags.push(tag.name);
    });
    _.forEach(self.generic_tags(), function(tag) {
      tags.push(tag.name);
    });
    return tags.join(',');
  });


  this.changeServiceChannel = function(newChannelId, callback) {
    $.ajax({
      url: '/tasks/' + self.id + '/change_service_channel',
      method: 'POST',
      dataType: 'json',
      data: {'channel_id': newChannelId},
      success: function(reply) {
        callback(reply);
      },
      error: function(a,b,c) {
        alert(a);
      }
    });
  };

  this.assignToAgent = function(newAgentId, callback) {
    $.ajax({
      url: '/tasks/' + self.id + '/assign_to_agent',
      method: 'POST',
      dataType: 'json',
      data: {'agent_id': newAgentId},
      success: function(reply) {
        callback(reply);
      },
      error: function(a,b,c) {
        alert(a);
      }
    });
  };

  this.refreshWaitingTimeout = function(callback) {
    $.ajax({
      url: 'tasks/' + self.id + '/refresh_waiting_timeout',
      method: 'POST',
      dataType: 'json',
      done: function(updatedTask) {
        self.updateTask(updatedTask);
        if(callback) {
          callback(updatedTask);
        }
      },
      fail: function(response) {
        if(response.status == 405) {
          var message;
          if(response.responseJSON && response.responseJSON.task) {
            message = I18n.t('user_dashboard.task_is_already_in_work', {agent: self.data.agent.first_name + ' ' + self.data.agent.last_name});
          } else {
            message = 'You cannot do this action';
          }
          bootbox.alert(message, function() {
            // ??? Setting the tasks.errors variable?
            //bootbox.alert(message, =>
            //  @set(@parse(response.responseJSON?.task)) if task
            //)
          });
        }
      }
    });
  };

  this.managementDirty = false;
  this.managementMarkDirty = function() {
    self.managementDirty = true;
  };

  this.isUrgent.subscribe(function() { self.managementMarkDirty() });
  this.serviceChannelId.subscribe(function() { self.managementMarkDirty() });
  this.assigned_to_user_id.subscribe(function() { self.managementMarkDirty() });

  this.managementResetDirty = function() {
    self.managementDirty = false;
  };

  this.toJSON = function() {
    var cpy = ko.toJS(self);
    delete cpy.messages;
    delete cpy.skills;
    delete cpy.flags;
    delete cpy.data;
    return cpy;
  };

}
