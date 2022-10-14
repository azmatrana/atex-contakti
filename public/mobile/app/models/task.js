define([
  "jquery",
  "knockout",
  "i18next",
  "moment",
  "api",
  "appdata",
  "models/message",
  "models/generic_tag",
  "models/skill"
], function ($,
             ko,
             i18n,
             moment,
             api,
             appdata,
             Message,
             GenericTag,
             Skill) {
  function Task(data) {
    var self = this;
    this._originalData = data;
    this.priorityClass = ko.observable(' priority-no');
    this.id = data.id;
    this.media_channel = data.media_channel;
    this.state = ko.observable(data.state);
    this.created_at = new Date(Date.parse(data.created_at)).toLocaleString();
    this._created_at = Date.parse(data.created_at);
    this.createdAtDate = new Date(data.created_at);
    this.noteBody = ko.observable(data.note_body);
    this.showNoteForm = ko.observable(data.note_body && data.note_body !== '');
    this.isCallback = ko.pureComputed( function() {
      var lastSubject = 'unanswered_call';
      data.messages.forEach(function(message) {
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
    this.format_time_till_red_alert = data.format_time_till_red_alert.indexOf(" ") ? data.format_time_till_red_alert.split(" ")[0] : data.format_time_till_red_alert;
    this.service_channel = ko.observable(data.service_channel);
    this.follow_user_ids = ko.observableArray(data.follow_user_ids);

    if(data.service_channel){
      this.serviceChannelName  = ko.observable(data.service_channel.name);
    }

    this.showSendByUser = ko.pureComputed(function() {
      return self._originalData.send_by_user;
    });

    this.sendByUserFullName = ko.pureComputed(function() {
      if (!self.showSendByUser()) return;
      return self._originalData.send_by_user.first_name + ' ' + self._originalData.send_by_user.last_name;
    });

    this.closedByUserFullName = ko.pureComputed(function() {
      if (!self.showClosedByUser()) return;
      return self._originalData.closed_by_user.first_name + ' ' + self._originalData.closed_by_user.last_name;
    });

    this.showClosedByUser = ko.pureComputed(function() {
      return self.state() === 'ready' && self._originalData.closed_by_user;
    });

    this.agentName = ko.pureComputed(function() {
      if (!self._originalData.agent) return;
      return self._originalData.agent.first_name + ' ' + self._originalData.agent.last_name;
    });

    this.lastMessage  = ko.pureComputed( function() { return self.messages()[self.messages().length - 1];});

    if (this.service_channel()) {
      this.service_channel_id = ko.observable(this.service_channel().id);
    } else {
      this.service_channel_id = ko.observable(null);
    }
    this.service_channel_id.subscribe(function (newId) {
      // Update the service_channel binding
      ko.utils.arrayForEach(appdata.getServiceChannels(), function (sc) {
        if (sc.id == newId) {
          self.service_channel(sc);
          return false;
        }
      });
    });

    if (data.data) {
      this.caller_name = ko.observable(data.data.caller_name);
    } else {
      this.caller_name = ko.observable(null);
    }

    this.buildArray = function(dataSource, objClass) {
      var tempArray = [];
      if (!dataSource) return tempArray;
      ko.utils.arrayForEach(dataSource, function(item) {
        tempArray.push(new objClass(item, self));
      });
      return tempArray;
    };

    this.messagesSorting = false;
    this.sortMessages = function () {
      if (!self.messagesSorting) {
        self.messagesSorting = true;
        self.messages.sort(function (a, b) {
          return moment(a.created_at).isBefore(moment(b.created_at));
        });
        self.messagesSorting = false;
      }
    };

    this.messages = ko.observableArray();

    // Sort when even single item is changed
    this.messages.subscribe(this.sortMessages, null, "arrayChange");
    // And sort when whole observableArray replaced
    this.messages.subscribe(this.sortMessages);

    var messages = Message.fromArray(data.messages, this);
    this.messages(messages);

    this.flags = ko.observableArray(data.flags);

    this.state_label = i18n.t("app:tasks.state." + this.state());
    // call counter
    this.call_counter = function() {
      if (data.call_counter === undefined) {
        return null;
      }
      return data.call_counter
    };

    // Actions
    this.canFollow = ko.observable(false);
    this.canUnfollow = ko.observable(false);
    this.canLock = ko.observable(false);
    this.canUnlock = ko.observable(false);
    this.canClose = ko.observable(false);
    this.canStart = ko.observable(false);
    this.canRestart = ko.observable(false);
    this.canPause = ko.observable(false);

    this.hasPhoneNumber = ko.computed(this.hasPhoneNumber.bind(this));
    this.canSendSms = ko.computed(this.canSendSms.bind(this));
    this.canSendEmail = ko.computed(this.canSendEmail.bind(this));
    this.canCall = ko.computed(this.canCall.bind(this));
    if (Task.mediaChannelPropertyGetters['media_channel_label'][this.media_channel] === undefined) {
      this.media_channel_label = "";
    } else {
      this.media_channel_label = Task.mediaChannelPropertyGetters['media_channel_label'][this.media_channel];
    }
    if (self.media_channel === "call") {
      this.callButtonClicked = () => {
        !!(data.callback_task_mark_as_done_on_call) &&
        self.canClose() &&
        self.close('neutral')

        return true;
      }
    }
    this.label = ko.computed(this._label.bind(this));
    this.callerName = ko.computed(this.callerName.bind(this));
    this.emailSubject = ko.computed(this._emailSubject.bind(this));
    this.from = ko.computed(this.from.bind(this));
    this.phoneNumberRef = ko.computed(this._getCallHref.bind(this));

    this.agent = ko.observable(data.agent);
    this.assigned_to_user_id = ko.observable(data.assigned_to_user_id);
    this.created_at_i18n = moment(data.created_at).locale(i18n.options.lng).format('ddd l LT');

    this.isUrgent = ko.computed(this._isUrgent.bind(this));
    this.minutes_till_red_alert = data.minutes_till_red_alert;
    this.minutes_till_yellow_alert = data.minutes_till_yellow_alert;

    this.generic_tags = ko.observableArray(this.buildArray(data.generic_tags, GenericTag));
    this.skills = ko.observableArray(this.buildArray(data.skills, Skill));
    this.tagsAsString = ko.observable(this._getTagsAsString());

    this._taskUpdated(data);

    // Returns one of 3 clock icons based on how old a task is
    // Expects data.minutes_till_red_alert and
    // data.minutes_till_yellow_alert to be set
    this.getClockClass = function () {
      if (data.minutes_till_red_alert <= 0) {
        return 'status-urgent';
      } else if (data.minutes_till_yellow_alert <= 0) {
        return 'status-warning';
      } else {
        return 'status-ok';
      }
    };

    this.clockClass = ko.observable(this.getClockClass());

    this.getPriorityClass = function (priority) {
      var priorityCssClass;
      switch (priority) {
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

    this.priorityClass(this.getPriorityClass(data.priority));


    this.formatCountDownTime = function () {
      var charBefore = data.minutes_till_red_alert < 0 ? '+' : '';
      var totalMinutes = Math.abs(data.minutes_till_red_alert);
      var duration = moment.duration(totalMinutes, 'minutes');
      if (totalMinutes >= 525600) {
        return charBefore + duration.years() + i18n.t('app:time.short.year');
        // 1 or more years
      } else if (totalMinutes >= 43800) {
        // 1 or more months
        return charBefore +
          duration.months() + i18n.t('app:time.short.month') +
          duration.days() + i18n.t('app:time.short.day');
      } else if (totalMinutes >= 1440) {
        // 1 or more days
        return charBefore +
          duration.days() + i18n.t('app:time.short.day');
      } else if (totalMinutes >= 180) {
        // 3 or more hours
        return charBefore +
          duration.hours() + i18n.t('app:time.short.hour');
      } else if (totalMinutes >= 60) {
        // 1..3 hours
        return charBefore +
          duration.hours() + i18n.t('app:time.short.hour') +
          duration.minutes() + i18n.t('app:time.short.min');
      } else {
        return charBefore +
          duration.minutes() + i18n.t('app:time.short.min');
      }
    };

    this.timer = ko.observable(this.formatCountDownTime());

    if (data.minutes_till_red_alert > -180) { // live timers not worth it for +3h
      this.loop = setInterval(function () {
        data.minutes_till_red_alert = data.minutes_till_red_alert - 1;
        self.clockClass(self.getClockClass());
        self.timer(self.formatCountDownTime());
      }, 60 * 1000);
    }
  }

  Task.prototype.combinedMessages = function() {
    return ko.utils.arrayFilter(this.messages(), function(message) {
      if(!message._originalData) {
        return false;
      }
      return true;
    }).sort(function (left, right) {
      return moment.utc(right.created_at).diff(moment.utc(left.created_at))
    });;
  };


  Task.prototype.firstNotInternalNotSmsMessage = function () {
    return ko.utils.arrayFirst(this.messages(), function(mess) {
      return !mess.isInternal() && !mess._originalData.sms;
    });
  };

  Task.prototype.firstNotSmsMessage = function () {
    return ko.utils.arrayFirst(this.messages(), function(mess) {
      return !mess._originalData.sms;
    });
  };

  Task.fromArray = function (tasks) {
    var models = [];

    if ($.isArray(tasks)) {
      $.each(tasks, function () {
        models.push(new Task(this));
      });
    }

    return models;
  };

  Task.prototype.isCallback = function() {
    alert("models")
    var lastSubject = 'unanswered_call';
    this.messages().forEach(function(message) {
      if (message.title() && message.title().length > 0) {
        if(message.channel_type === 'call'){
          lastSubject = [message.title().split(' ')[0], message.title().split(' ')[1]].join('_').toLowerCase();
        } else {
          lastSubject = message.title()
        }
      }
    });
    if(lastSubject === 'unanswered_call') {
      return true;
    } else {
      return false;
    }
  };

  Task.prototype.isSent = function() {
    return this.messages()[0].inbound;
  };

  Task.prototype.recieverNumber = function () {
    if (this.messages()[0].inbound) {
      return this.messages()[0].to;
    } else {
      return this.messages()[0].from;
    }
  };

  Task.mediaChannelPropertyGetters = {
    label: {
      "call": function (caller_name, message) {
        return message.from || caller_name || "\u203A " + message.to();
      },
      "email": function (caller_name, message) {
        return message.from_email || message.from || message.title() || "\u203A " + message.to();
      },
      "web_form": function (caller_name, message) {
        return message.from || message.from_email || message.title() || "\u203A " + message.to();
      },
      "sip": function (caller_name, message) {
        return Task.mediaChannelPropertyGetters.label["call"](caller_name, message);
      },
      "chat": function (caller_name, message) {
        return message.from || message.from_email || message.title() || "\u203A " + message.to();
      },
      "internal": function (caller_name, message) {
        return message.from || message.from_email || message.title() || "\u203A " + message.to();
      },
      "sms": function (caller_name, message) {
        if (message.inbound) {
          return message.from;
        } else {
          return message.to()
        }
      }
    },
    media_channel_label: {
      "call": i18n.t("app:tasks.media_channel.call"),
      "email": i18n.t("app:tasks.media_channel.email"),
      "web_form": i18n.t("app:tasks.media_channel.web_form"),
      "sip": i18n.t("app:tasks.media_channel.sip"),
      "chat": i18n.t("app:tasks.media_channel.chat"),
      "sms": i18n.t("app:tasks.media_channel.sms")
    }
  };

  Task.prototype._label = function () {
    if (Task.mediaChannelPropertyGetters['label'][this.media_channel] === undefined) {
      return '';
    }
    var message;
    if (this.messages().length > 0) {
      message = this.messages()[0];
    } else {
      message = {
        from: this.media_channel_label
      };
    }
    return Task.mediaChannelPropertyGetters['label'][this.media_channel](this.caller_name(), message);
  };
  Task.prototype._emailSubject = function () {
    var lastSubject = 'no subject';
    let messages = this.messages().sort(function (a, b) {
      var c = new Date(a.created_at);
      var d = new Date(b.created_at);
      return d - c;
    });

    messages.forEach(function (message) {
      if (lastSubject === 'no subject') {
        if (message.title() && message.title().length > 0) {
          lastSubject = message.title();
        }
      }
    });
    return lastSubject;
  };

  Task.prototype.emailSubject = function () {

    if (Task.mediaChannelPropertyGetters['label'][this.media_channel] === undefined) {
      return '';
    }
    var x = this.messages();
    var y;
    var title;
    var channel_type;
    if (x.length > 1) {
      y = x.sort(function (a, b) {
        var c = new Date(a.created_at);
        var d = new Date(b.created_at);
        return d - c;
      });
      debugger
      y.forEach(function(message) {
        if (message.title() && message.title().length > 0 && title === undefined) {
          title = message.title();
          channel_type = message.channel_type;
          return title;
        }
      });
    } else {
      title = this.messages()[0].title();
      channel_type = this.messages()[0].channel_type;
    }

    if (channel_type === 'call') {
      // if (title.split(',')[1]) {
        title = ([title.split(' ')[0], title.split(' ')[1]].join('_').toLowerCase()) === "unanswered_call" ? "Unanswered Call" : title
        // if (this.caller_name().replace(/\s/g, '') === title.split(',')[1].replace(/\s/g, ''))
        //   title = title.split(',')[0];
      //
      // }
    }
    return title
  };

  Task.prototype.callerName = function () {
    return this.caller_name();
  };

  Task.prototype.create = function () {
    var self = this;
    var message = this.messages()[0];
    var data = {
      type: 'internal',
      service_channel_id: self.service_channel_id(),
      agent_id: self.assigned_to_user_id(),
      messages_attributes: [
        {
          title: message.title(),
          description: message.description()
        }
      ]
    };
    return api.post('/tasks', data);
  };

  // Generic handler for making changes to task's properties via API call
  Task.prototype.update = function (data) {
    return api.patch('/tasks/' + this.id, data).done(this._taskUpdated.bind(this));
  };

  Task.prototype.delete = function (data) {
    return api.destroy('/tasks/' + this.id).done(this._taskUpdated.bind(this));
  };


  Task.prototype._taskUpdated = function (data) {
    this._updateAllowedActions(data);
  };

  Task.prototype._updateAllowedActions = function (data) {
    this.follow_user_ids(data.follow_user_ids || []);
    this.canFollow(!this.follow_user_ids().includes(api.currentUser.id));
    this.canUnfollow(this.follow_user_ids().includes(api.currentUser.id));
    this.canLock(data.may_lock);
    this.canUnlock(data.may_unlock);

    // Current logic: Only 'call's (i.e. callbacks, not sms'es) can be
    // closeable. There are currently 5 different media_channel (=types).
    this.canClose(
      data.state != 'ready'
    );

    this.canStart(data.may_start);
    this.canRestart(data.may_restart);
    this.canPause(data.may_pause);
  };

  Task.prototype.populateDynamicProperties = function (data) {
    data = data || this._originalData;

    $.each(Task.mediaChannelPropertyGetters, function (propertyName, getters) {
      var value = null,
        getter = getters[this.media_channel];

      if (typeof getter === "function") {
        value = getter(data, data.messages[0]);
      } else {
        value = getter;
      }

      this[propertyName] = value;
    }.bind(this));
  };

  Task.prototype.detailsUrl = function () {
    return "#tasks/" + this.id;
  };

  Task.prototype._getCallHref = function () {
    return 'tel:' + this.messages()[this.messages().length - 1].from;
  };

  Task.prototype._isUrgent = function () {
    return this.flags.indexOf('urgent') > -1;
  };

  Task.prototype._getTagsAsString = function () {
    var tags = [];
    ko.utils.arrayForEach(this.skills(), function (tag) {
      tags.push(tag.name);
    });
    ko.utils.arrayForEach(this.generic_tags(), function (tag) {
      tags.push(tag.name);
    });
    return tags.join(',');
  };

  Task.prototype.searchMatch = function (searchText, score) {
    var keywords = (searchText + "").split(/\s+/g),
      message = this.messages()[0],
      searchData = [
        this.label()
      ];

    $.each(this.messages(), function (i, message) {
      searchData.push(message.to());
      searchData.push(message.from);
      searchData.push(message.from_email);
      searchData.push(message.number);
      searchData.push(message.title());
      searchData.push(message.description());
    });
    searchData = searchData.filter(function (n) {
      return n !== undefined
    });

    var result = Task.recursiveSearch(searchData, keywords, !score);
    return score ? (result > 0) : result;
  };

  Task.prototype.serviceChannelMatch = function (ids) {
    return ids.indexOf(this._originalData.service_channel_id) > -1;
  };

  Task.prototype.mediaChannelMatch = function (mediaChannels) {
    return mediaChannels.indexOf(this.media_channel) > -1;
  };

  Task.prototype.priorityMatch = function (priorities) {
    // Copy the priorities array so that we don't modify the original
    var checkPriorities = priorities.slice(0);

    var urgentIndex = checkPriorities.indexOf('urgent');
    if (urgentIndex > -1) {
      checkPriorities.splice(urgentIndex);
      if (this.flags().indexOf('urgent') === -1) {
        return false;
      }
    }
    if (checkPriorities.length === 0) {
      return true;
    }
    if (checkPriorities.indexOf('yellow_alert') > -1 &&
      this.minutes_till_yellow_alert <= 0 &&
      this.minutes_till_red_alert > 0
    ) {
      return true;
    }
    if (checkPriorities.indexOf('red_alert') > -1 &&
      this.minutes_till_red_alert <= 0
    ) {
      return true;
    }
    return false;
  };

  // Tags are "free text" type of information associated with tasks
  Task.prototype.tagsMatch = function (tags) {
    var existingTags = this.tagsAsString().split(',');
    for (var i = 0; i < tags.length; i++) {
      if (existingTags.indexOf(tags[i]) === -1) {
        return false;
      }
    }
    return true;
  };

  Task.prototype.startDateMatch = function (date) {
    var compare = new Date(date.getTime());
    compare.setHours(0, 0, 0, 0);
    return this.createdAtDate >= compare;
  };

  Task.prototype.endDateMatch = function (date) {
    var compare = new Date(date.getTime());
    compare.setHours(23, 59, 59, 999);
    return this.createdAtDate <= compare;
  };

  Task.recursiveSearch = function (data, keywords, earlybail) {
    var t = $.type(data),
      score = 0;

    if (t === "string" || t === "number") {
      score += Task.keywordMatch(data, keywords, earlybail);
    } else if (t === "array") {
      $.each(data, function (key, value) {
        score += Task.recursiveSearch(value, keywords, earlybail);

        if (earlybail && score) {
          return false;
        }
      });
    }

    return score;
  };

  Task.keywordMatch = function (value, keywords, earlybail) {
    var matches = 0,
      str = (value + "").toLowerCase();

    $.each(keywords, function () {
      if (str.indexOf(this.toLowerCase()) >= 0) {
        matches++;

        if (earlybail) {
          return false;
        }
      }
    });

    return matches;
  };

  Task.prototype.isCallType = function () {
    return this.media_channel == "call" || this.media_channel == "sip";
  };

  Task.prototype.from = function () {
    return this.messages()[0] && this.messages()[0].from;
  };

  Task.prototype.hasPhoneNumber = function () {
    return this.isCallType() && this.from();
  };

  Task.prototype.canSendSms = function () {
    var message = this.messages()[0];
    if (message && message.sms) {
      return true;
    }
    return this.media_channel == "call" && this.hasPhoneNumber() || this.media_channel == "web_form" || this.media_channel == "email" || this.media_channel == "internal"  || this.media_channel == "chat";
  };

  Task.prototype.canSendEmail = function () {
    return this.media_channel == "web_form" || this.media_channel == "email" || this.media_channel == "internal" || this.media_channel == "chat";
  };

  Task.prototype.canCall = function () {
    return this.hasPhoneNumber();
  };

  Task.prototype.loadMessages = function () {
    if (!this.id)
      return null;

    return api.task_messages(this.id).done(this._messagesReceived.bind(this));
  };

  Task.prototype._messagesReceived = function (data) {
    if (!$.isArray(data))
      throw "Unexpected response, expected array";

    var messages = Message.fromArray(data);
    this.messages(messages);
  };

  Task.prototype.updateTask = function (newData) {
    if (this.id != newData.task.id) {
      return;
    }

    this.state(newData.task.state);
    this.service_channel(newData.task.service_channel);
    this.agent(newData.task.agent);

    this._messagesReceived(newData.task.messages);

    this._updateAllowedActions(newData.task);
    this.noteBody(newData.task.note_body);
    this.priorityClass(this.getPriorityClass(newData.task.priority));

    if(newData.task.skills) {
      this.skills(this.buildArray(newData.task.skills, Skill));
    }
    // if(newData.flags) {
    //   this.flags(this.buildArray(newData.flags, Flag));
    // }
    if(newData.task.generic_tags) {
      this.generic_tags(this.buildArray(newData.task.generic_tags, GenericTag));
    }
  };

  Task.prototype.follow = function () {
    return this.update({update_action: 'follow_task'});
  };

  Task.prototype.unfollow = function () {
    return this.update({update_action: 'unfollow_task'});
  };

  Task.prototype.lock = function () {
    return this.update({update_action: 'change_state', event: 'lock'});
  };

  Task.prototype.unlock = function () {
    return this.update({update_action: 'change_state', event: 'unlock'});
  };

  Task.prototype.close = function (result) {
    return this.update({update_action: 'change_state', event: 'close', result: result});
  };

  Task.prototype.restart = function () {
    return this.update({update_action: 'change_state', event: 'restart'});
  };

  Task.prototype.updateSettings = function (settingsData) {
    var self = this;
    return this.update({
      update_action: 'update_settings',
      is_urgent: !!settingsData.isUrgent,
      tags: self.tagsAsString(),
      service_channel_id: self.service_channel_id(),
      agent_id: self.assigned_to_user_id()
    }).success(function () {
      if (!!settingsData.isUrgent) {
        if (!self.isUrgent()) {
          self.flags.push('urgent');
        }
      } else if (self.isUrgent()) {
        self.flags.remove('urgent');
      }
    });
  };

  Task.prototype.reply = function (message) {
    var lastMessage = this.messages()[0];
    var data = {
      reply: {
        to: message.to(),
        title: message.title(),
        description: message.description(),
        in_reply_to_id: lastMessage.id
      }
    };
    if (message.sms) {
      data['reply']['is_sms'] = 1;
    }
    if (message.isInternal()) {
      data['reply']['is_internal'] = 1;
    }
    if (message.is_forward) {
      data['reply']['is_forward'] = 1;
    }
    return api.post('/tasks/' + this.id + '/reply', data).done(this._taskReplied.bind(this));
  };

  Task.prototype.replyFormData = function (formData) {

    return api.post('/tasks/' + this.id + '/reply', formData).done(this._taskReplied.bind(this));
  };

  Task.prototype.changeStateEvent = function(newState, callback) {
    var data = { event: newState };
    return api.post('/tasks/' + this.id + '/change_task_state', data).done(callback);
  };

  Task.prototype._taskReplied = function (data) {
    var newMessage = new Message($.extend(data.message, {
      caller_name: this.caller_name()
    }));
    this.messages.unshift(newMessage);
  };

  return Task;
});
