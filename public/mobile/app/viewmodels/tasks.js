define([
  "jquery",
  "durandal/app",
  "plugins/router",
  "knockout",
  "i18next",
  "moment",
  "api",
  "appdata",
  "models/task",
  "models/message",
  "models/service_channel",
  "models/media_channel",
  "models/filter_store",
  "jquery-ui",
  "bootstrap/modal",
  "bootstrap/tab",
  "tokenfield",
  "pickadate",
  "pickadate-date",
  "select2"
], function ($,
             app,
             router,
             ko,
             i18n,
             moment,
             api,
             appdata,
             Task,
             Message,
             ServiceChannel,
             MediaChannel,
             FilterStore) {

  function Tasks() {
    var self = this;
    this.i18n = i18n;

    this.appSettings = ko.observable({
      password: '',
      passwordConfirmation: '',
      language: i18n.lng()
    });
    // Languages hard coded in their native translations
    var availableLanguages = [
      {key: 'fi', name: i18n.t('app:language.fi', {lng: i18n.lng()})},
      {key: 'en', name: i18n.t('app:language.en', {lng: i18n.lng()})}
    ];
    this.availableLanguages = [];
    ko.utils.arrayForEach(availableLanguages, function (lang) {
      if (i18n.lng() === lang.key) {
        self.availableLanguages.unshift(lang);
      } else {
        self.availableLanguages.push(lang);
      }
    });
    if (api.currentUser) {
      var apiCurrentUser = api.currentUser;
      apiCurrentUser.signature = apiCurrentUser.signature.split('<br>').join('\n');
      this.currentUser = ko.observable(apiCurrentUser);
    }
    this.appSettingsActive = ko.observable(false);

    this.tasks = ko.observableArray([]);
    this.tasks.subscribe(this._sortTasks.bind(this));
    this.tasksPromise = ko.observable(null);
    this.readyTasksPromise = ko.observable(null);
    this.initialReadyTasksFetched = false;

    this.filter = ko.observable(new FilterStore());
    this.filteringActive = ko.observable(false);

    this.taskAssociationFilterLabel = ko.computed(this._taskAssociationFilterLabel.bind(this));

    this.filteredTasks = ko.computed(this._getFilteredTasks.bind(this, true, true, true));
    this.fetchedReadyTasksCount = 0;

    this.taskCounts = ko.computed(this._getTaskCounts.bind(this));

    this.selectedTask = ko.observable();
    this.selectedMessage = ko.observable();
    this.selectedResult = ko.observable('neutral');

    this.smsMessage = ko.observable();
    this.emailMessage = ko.observable();
    this.changeTaskStateMessage = ko.observable();
    this.isReplyEmailSending = ko.observable(false);

    this.availableAgents = ko.computed(this._getAvailableAgents.bind(this));
    this.serviceChannels = ko.observableArray([]);
    this.mediaChannels = ko.observableArray([]);

    this.selectedTask.subscribe(function () {
    });
    this.noteSavedNotification = ko.observable(false);
    this.handleTemplateSelect = function(){
      self.smsMessage().description(event.target.value);
    }

    this.showDeleteModal = function() {
      $('#delete-task-modal').modal('show');
    };

    this.hideDeleteModal = function() {
      $('#delete-task-modal').modal('hide');
    };

    this.deleteTaskClicked = function() {
      self.hideDeleteModal();
      self.selectedTask().delete();
    };

    app.on("session:reset", this.onSessionReset.bind(this));

    appdata.runAfterDataLoaded(function () {
      ko.utils.arrayPushAll(self.serviceChannels, appdata.getServiceChannels());
      ko.utils.arrayPushAll(self.mediaChannels, appdata.getMediaChannels());
      self.filter().selectedServiceChannels(ko.utils.arrayMap(self.serviceChannels(), function (sc) {
        return sc.id;
      }));

      self.filteredServiceChannels = ko.computed(self._getFilteredServiceChannels.bind(this));

      // Force refilter after data has been loaded
      self.filter.notifySubscribers();
    });
  }

  Tasks.prototype._getTaskCounts = function () {
    var counts = {
        new: 0,
        open: 0,
        waiting: 0,
        ready: 0
      },
      total = 0;

    ko.utils.arrayForEach(this._getFilteredTasks(true, true, true), function (task) {
      var state = task.state();
      counts[state] = (counts[state] || 0) + 1;
      total++;
    });

    counts.all = total;
    return counts;
  };

  Tasks.associationFilters = [
    "open_to_all",
    "created_by_me",
    "assigned_to_me",
    "assigned_to_other",
    "i_am_following"
  ];

  // These define the logical conditions (computing) making each filter effective
  Tasks.associationFilterMatchers = {
    "open_to_all": function (task) {
      return !task.agent() || task.state() === 'ready';
    },
    "created_by_me": function (task) {
      return task.created_by_user_id == api.currentUser.id;
    },
    "assigned_to_me": function (task) {
      return task.agent() && task.agent().id == api.currentUser.id;
    },
    "assigned_to_other": function (task) {
      return task.agent() && task.agent().id != api.currentUser.id;
    },
    "i_am_following": function (task) {
      return task.follow_user_ids().includes(api.currentUser.id);
    }
  };

  // Simply sort 'tasks' list based on timestamp field
  Tasks.prototype._sortTasks = function () {
    if (this.tasks._isSorting) {
      return true;
    } else {
      this.tasks._isSorting = true;
      this.tasks.sort(function (left, right) {
        var priorityDiff = right._originalData.priority - left._originalData.priority;
        var dateA=new Date(right._created_at);
        var dateB=new Date(left._created_at);
        var dateDiff;
        if(left._originalData.priority == right._originalData.priority) {
          if(left._originalData.priority == 0)
            dateDiff = dateA - dateB
          else
            dateDiff = dateB - dateA
        }
        else {
          dateDiff = dateB - dateA
        }

        return priorityDiff || dateDiff;
      });

      this.tasks._isSorting = false;
    }
  };

  Tasks.prototype.saveNote = function () {
    var self = this;
    var data = {
      note: {
        body: this.selectedTask().noteBody()
      }
    };
    api.post('/tasks/' + this.selectedTask().id + '/note', data).done(function () {
      self.noteSavedNotification(true);
      setTimeout(function () {
        self.noteSavedNotification(false);
      }, 2000);
    })
  };

  Tasks.prototype.clearNote = function () {
    this.selectedTask().noteBody('');
  };

  Tasks.prototype.toggleNoteForm = function () {
    this.selectedTask().showNoteForm(!this.selectedTask().showNoteForm());
  };

  Tasks.prototype.addAttachment = function(obj, e) {
    var clone = $(e.currentTarget).siblings('.fileupload.template').clone();
    var fileField = clone.find(".file-field");
    fileField.prop('disabled', false);
    fileField.attr('name', fileField.attr('name').replace(/(.*\[)0(\]\[file\])/, "$1"+new Date().getTime()+"$2"));
    $(e.currentTarget).closest('.fileupload-section').append(clone.removeClass('hidden template').addClass('attachments'));
  };

  // Resets UI state regarding choices and search words: back to defaults
  Tasks.prototype.onSessionReset = function () {
    // If promise exists, signal the done handler that the tasks shouldn't be loaded.
    this.tasksPromise(null);
    this.readyTasksPromise(null);
    this.initialReadyTasksFetched = false;
    // If there are tasks, reset to defaults, also reset category filter
    if (this.tasks() && this.tasks().length) {
      this.tasks([]);
      this.selectedTask(null);
      this.selectedTaskId = null;
      this.filter().selectedStatuses(['new', 'open', 'waiting']);
      this.filter().searchWords("");
      this.filter().selectedCategories(['open_to_all', 'created_by_me', 'assigned_to_me']);
    }
  };

  Tasks.prototype.activate = function (taskId) {
    if (!api.currentUser) {
      router.navigate("", {replace: true, trigger: true});
      return;
    }

    app.trigger("menu:toggle", true);
    app.trigger("navbar:hide");

    if (!this.tasksPromise() && !this.tasks().length) {
      this.tasksPromise(api.tasks().done(this._tasksReceived.bind(this)));
    }

    if (!this.readyTasksPromise() && !this.initialReadyTasksFetched) {
      this.readyTasksPromise(api.readyTasks().done(this._readyTasksReceived.bind(this)));
      this.initialReadyTasksFetched = true;
    }

    if (taskId) {
      this.setSelectedTask(taskId);
    } else if (this.selectedTask()) {
      this.clearSelectedTask();
    }
  };

  Tasks.prototype.onTaskModalHidden = function () {
    router.navigate("tasks", {replace: true, trigger: true});
  };

  Tasks.prototype.clearSelectedTask = function () {
    if (this.selectedTask()) {
      $("#task-modal").modal("hide");
    }

    this.selectedTaskId = null;
    this.selectedTask(null);
  };

  Tasks.prototype.setSelectedTask = function (taskId) {
    this.selectedTaskId = taskId || this.selectedTaskId;

    if (!this.selectedTaskId)
      return;

    var task = null,
      matchId = this.selectedTaskId;

    var task = ko.utils.arrayFirst(this.tasks(), function(t) {
      return t.id == matchId;
    });

    this.selectedTask(task);

    this.openTaskModal();
  };

  // Slides open a Task for details viewing
  Tasks.prototype.openTaskModal = function () {
    var task = this.selectedTask();
    if (task) {
      $("#task-modal").modal("show");
      var promise = task.loadMessages();
      if (promise) {
        var self = this;
        promise.done(function () {
          self.selectedMessage(task.messages()[0]);
        })
      } else {
        this.selectedMessage(null);
      }
    }
  };

  Tasks.prototype.afterTaskFiltersRender = function (nodes, viewModel) {
    var selectElems = [
      '#filter_categories',
      '#filter_status',
      '#filter_service_channels',
      '#filter_media_channel',
      '#filter_priority'
    ];
    $(selectElems.join(',')).select2({
      formatNoMatches: function () {
        return '';
      },
      width: '100%',
      hideSelectionFromResult: true
    });

    viewModel._initializeTagsInput($('input#filter_tags'));

    var keyboard = false;
    $('#filter_daterange_start, #filter_daterange_end').on('setup', function () {
      var timeString = $(this).val();
      var time = moment(timeString, 'YYYY-MM-DD');
      if ($(this).is('#filter_daterange_start')) {
        if (time) {
          var newTime = time.startOf('day');
          viewModel.filter().selectedDateRangeStart(newTime);

          // Ending date must be after start date
          var end = viewModel.filter().selectedDateRangeEnd();
          if (end && end.isBefore(newTime)) {
            $('#filter_daterange_end').val(null);
          }
        } else {
          viewModel.filter().selectedDateRangeStart(null);
        }
      } else {
        var newTime = null;
        if (time) {
          newTime = time.endOf('day');
          var start = viewModel.filter().selectedDateRangeStart();
          if (start && newTime.isBefore(start)) {
            newTime = null;
          }
        }
        if (newTime) {
          viewModel.filter().selectedDateRangeEnd(newTime);
        } else if (time) {
          $(this).val(null);
        }
      }
    }).on('keydown', function () {
      // Wait until blur in case keyboard
      keyboard = true;
    }).on('blur', function () {
      $(this).trigger('setup');
    }).on('change', function () {
      if (!keyboard) {
        $(this).trigger('setup');
      }
    });
  };

  Tasks.prototype.afterTaskModalRender = function (nodes, viewModel) {
    // Give some time for everything to be ready for rendering
    setTimeout(function () {
      viewModel.openTaskModal();
    }, 500);
  };

  Tasks.prototype.afterTaskSettingsRender = function (nodes, viewModel) {
    viewModel._initializeTagsInput($('input#tags'));
  };

  Tasks.prototype.tasks = [];

  Tasks.prototype._initializeTagsInput = function (input) {
    input.on('tokenfield:createdtoken', function (e) {
      var target = $(e.relatedTarget);
      var targetText = target.text();
      targetText = targetText.substring(0, targetText.length - 1);
      ko.utils.arrayForEach(appdata.getAvailableTags(), function (tag) {
        if (tag.label === targetText && tag.category === 'skills') {
          switch (tag.priority) {
            case 0:
              target.addClass('priority-0');
            case 1:
              target.addClass('priority-1');
            case 2:
              target.addClass('priority-2');
            case 3:
              target.addClass('priority-3');
            default:
              target.addClass('priority-no');
          };
          target.css('background-color', '#0dc0c0');
        }
      });
    }).tokenfield({
      delimiter: [',', ' '],
      createTokensOnBlur: true,
      showAutocompleteOnFocus: true,
      autocomplete: {
        minLength: 0,
        delay: 100,
        source: appdata.getAvailableTags()
      }
    });
  };

  Tasks.prototype._tasksReceived = function (tasks) {
    if (!this.tasksPromise())
      return; // session:reset event has been triggered, don't do anything with the results.

    this.tasksPromise(null);
    var models = Task.fromArray(tasks);
    ko.utils.arrayPushAll(this.tasks, models);

    this.setSelectedTask();
    api.danthesSubscribeTasks(this._danthesIncomingTask.bind(this));
  };

  Tasks.prototype._readyTasksReceived = function (tasks) {
    if (!this.readyTasksPromise())
      return;
    this.fetchedReadyTasksCount = this.fetchedReadyTasksCount + tasks.length;
    this.readyTasksPromise(null);
    var models = Task.fromArray(tasks);
    // Premature optimization! This triggered sorting, even though no models were added :)
    if (models.length > 0) {
      ko.utils.arrayPushAll(this.tasks, models);
    }
  };

  Tasks.prototype._danthesIncomingTask = function (taskData) {
    var foundTask = ko.utils.arrayFirst(this.tasks(), function (task) {
      return task.id == taskData.task.id;
    });
    // checks whether there already is a existing Task - then just update its data
    if (foundTask) {
      if (taskData.task.deleted_at){
        if (this.selectedTask() && this.selectedTask().id === taskData.task.id) {
          this.clearSelectedTask();
        }
        this.tasks.remove(foundTask)
      } else {
        foundTask.updateTask(taskData);

        foundTask.tagsAsString(foundTask._getTagsAsString());
      }
      $('input#tags').tokenfield('setTokens', foundTask.tagsAsString());
    } else {
      // ...else if Task not found, then create a new task
      this.tasks.push(new Task(taskData.task));
    }
  };

  Tasks.prototype._taskAssociationFilterLabel = function () {
    var cats = this.filter().selectedCategories();
    if (cats.length < 1) {
      return '';
    }
    var label = i18n.t("app:tasks.association_filter." + cats[0]);
    if (cats.length > 1) {
      return label + ' (+' + (cats.length - 1) + ')';
    }
    return label;
  };

  Tasks.prototype.setStateFilter = function (state) {
    if (state === null) {
      this.filter().selectedStatuses([]);
    } else {
      this.filter().selectedStatuses([state]);
    }

    // Select2 does not update without this
    $('#filter_status').trigger('change');
    return false;
  };

  Tasks.prototype.toggleAssociationFilter = function () {
    var cats = this.filter().selectedCategories();
    var currentValue = cats.length > 0 ? cats[0] : 'assigned_to_me';

    var oldIndex = Tasks.associationFilters.indexOf(currentValue),
      newIndex = (oldIndex + 1) % Tasks.associationFilters.length,
      newVal = Tasks.associationFilters[newIndex];

    var test = [newVal];
    this.filter().selectedCategories([newVal]);

    // Select2 does not update without this
    $('#filter_categories').trigger('change');

    return false;
  };

  Tasks.prototype._getFilteredTasks = function (searchFilter, assocFilter, stateFilter) {
    var search = this.filter().searchWords(),
      assoc = this.filter().selectedCategories(),
      state = this.filter().selectedStatuses(),
      serviceChannels = this.filter().selectedServiceChannels(),
      mediaChannels = this.filter().selectedMediaChannels(),
      priorities = this.filter().selectedPriorities(),
      tags = this.filter().selectedTags(),
      startDate = this.filter().selectedDateRangeStart(),
      endDate = this.filter().selectedDateRangeEnd();

    if (startDate) {
      startDate = startDate.toDate();
    }
    if (endDate) {
      endDate = endDate.toDate();
    }

    return ko.utils.arrayFilter(this.tasks(), function (task) {
      if (assocFilter && assoc.length > 0) {
        var match = false;
        for (var i = 0; i < assoc.length; i++) {
          var matcher = Tasks.associationFilterMatchers[assoc[i]];

          // It is enough to find one matching filter
          if (matcher(task)) {
            match = true;
            break;
          }
        }
        if (!match) {
          return false;
        }
      }

      if (stateFilter && state.length > 0 && state.indexOf(task.state()) === -1)
        return false;

      if (searchFilter && search && !task.searchMatch(search, false))
        return false;

      if (serviceChannels.length > 0 && !task.serviceChannelMatch(serviceChannels))
        return false;

      if (mediaChannels.length > 0 && !task.mediaChannelMatch(mediaChannels))
        return false;

      if (priorities.length > 0 && !task.priorityMatch(priorities))
        return false;

      if (tags && !task.tagsMatch(tags))
        return false;

      if (startDate && !task.startDateMatch(startDate))
        return false;

      if (endDate && !task.endDateMatch(endDate))
        return false;

      return true;
    });
  };

  Tasks.prototype._getFilteredServiceChannels = function () {
    var self = this;
    var channels = appdata.getChannelTypes();
    var filteredServiceChannels = {};

    $.each(channels, function (key, type) {
      var scids = [];
      ko.utils.arrayForEach(self.mediaChannels, function (mc) {
        if (mc.type == type && scids.indexOf(mc.service_channel_id) === -1) {
          scids.push(mc.service_channel_id);
        }
      });
      filteredServiceChannels[key] = ko.utils.arrayFilter(self.serviceChannels, function (sc) {
        return scids.indexOf(sc.id) > -1;
      });
    });

    return filteredServiceChannels;
  };

  // Availability means the agent is ONLINE
  Tasks.prototype._getAvailableAgents = function () {
    var self = this;
    var agents = [];
    ko.utils.arrayForEach(appdata.getServiceChannels(), function (sc) {
      // TODO: Get the agents
    });
    return agents;
  };

  Tasks.prototype.onMessageExpanded = function (message) {
    this.selectedMessage(message);
  };

  Tasks.prototype.onTaskListScroll = function (a, b) {
    var states = this.filter().selectedStatuses();
    if (states.indexOf('ready') > -1) {
      if (!this._isScrolledToBottom()) {
        return;
      }
      if (!this.readyTasksPromise()) {
        var offset = this.fetchedReadyTasksCount;
        this.readyTasksPromise(api.readyTasks(offset).done(this._readyTasksReceived.bind(this)));
      }
    }
  };

  Tasks.prototype._isScrolledToBottom = function () {
    var elem = $('#tasks-list');
    if (elem.scrollTop() + elem.innerHeight() >= elem[0].scrollHeight) {
      return true;
    }
    return false;
  };

  Tasks.prototype.onFollowTask = function () {
    this.selectedTask().follow();
  };

  Tasks.prototype.onUnfollowTask = function () {
    this.selectedTask().unfollow();
  };

  Tasks.prototype.onLockTask = function () {
    this.selectedTask().lock();
  };

  Tasks.prototype.onUnlockTask = function () {
    this.selectedTask().unlock();
  };

  Tasks.prototype.setResult = function (result) {
    this.selectedResult(result);
  };

  Tasks.prototype._hideResultModal = function () {
    $('#result-modal').modal('hide');
  };

  Tasks.prototype.onCancelAppSettings = function () {
    this.appSettingsActive(false);

    this.appSettings().password = '';
    this.appSettings().passwordConfirmation = '';

    $('#app-settings-modal').modal('hide');
  };

  Tasks.prototype.onConfirmAppSettings = function () {
    var self = this;
    var appSettings = this.appSettings();
    var user = this.currentUser();
    api.updateUser(user, {
      password: appSettings.password,
      passwordConfirmation: appSettings.passwordConfirmation
    }).done(function (updatedData) {
      // Update the token for the user
      user.token = updatedData.token;
      api.currentUser.token = updatedData.token;
      api.saveSession();

      var lng = i18n.lng();
      if (lng !== appSettings.language) {
        i18n.setLng(appSettings.language);
        window.location.reload();
      } else {
        self.onCancelAppSettings();

        $('#app-settings-modal').modal('hide');
      }
    });
  };

  Tasks.prototype.onConfirmFilter = function () {
    this.filteringActive(false);
    $('#filter-modal').modal('hide');
  };

  Tasks.prototype.onSendSms = function () {
    // TODO: Fetch SMS templates
    var task = this.selectedTask();
    var selectedMessage = this.selectedMessage() || task.messages()[0];
    var recipient = selectedMessage.from;

    if (!recipient.match(/^\+?[0-9 ]+$/)) {
      // In case the last message was a response from the agent, the
      // "form" field does not contain a number but the customer agent's
      // name. In this case we could assume that the "to" field contains
      // the number but this feature would be broken in case the
      // possibility to respond to these messages is added later.
      recipient = '';
    }

    var message = new Message({
      task_id: task.id,
      channel_type: 'internal',
      sms: true,
      description: '',
      to: recipient,
      caller_name: selectedMessage.caller_name
    });
    this.smsMessage(message);

    $("#sms-modal").modal("show");
  };
  Tasks.prototype.onCancelSms = function () {
    $("#sms-modal").modal("hide");
    this.smsMessage(null);
  };
  Tasks.prototype.onConfirmSmsSend = function () {
    var task = this.selectedTask();
    var message = this.smsMessage();
    task.reply(message).done(this._smsMessageSent.bind(this));
  };
  Tasks.prototype.onCancelSettings = function () {
    $('#settings-modal').modal("hide");
  };
  Tasks.prototype.onConfirmSettings = function () {
    var isUrgent = $("#task_priority").val() === 'urgent';
    this.selectedTask().updateSettings({
      isUrgent: isUrgent
    });
    $('#settings-modal').modal("hide");
  };
  Tasks.prototype._smsMessageSent = function () {
    this.onCancelSms();
    // Set the latest message as the selected one
    this.selectedMessage(this.selectedTask().messages()[0]);
  };

  Tasks.prototype.onSendEmail = function () {
    var task = this.selectedTask();
    // var selectedMessage = this.selectedMessage() || task.firstNotSmsMessage();
    var selectedMessage = task.firstNotSmsMessage();
    var isInternal = false;
    var channel = 'email';
    if (selectedMessage.channel_type === 'internal') {
      channel = 'internal';
      var isInternal = true;
    }
    var message = new Message({
      task_id: task.id,
      channel_type: channel,
      is_internal: isInternal,
      title: 'RE: ' + selectedMessage.title(),
      to: isInternal ? '' : selectedMessage.from,
      caller_name: selectedMessage.caller_name,
      service_channel_name: task.service_channel.name
    });
    message.isInternal.subscribe(function (isInternal) {
      if (isInternal) {
        message.to('');
      } else {
        message.to(selectedMessage.from);
      }
    });
    this.emailMessage(message);

    $("#email-modal").modal("show");
  };
  Tasks.prototype.onUpdateEmailMessageType = function () {
    console.log("UPDATE");
  };
  Tasks.prototype.onCancelEmail = function () {
    $("#email-modal").modal("hide");
    this.emailMessage(null);
  };
  Tasks.prototype.onConfirmEmailSend = function (data, event) {

    var form = $(event.target).closest('form');
    var isInternal = $("input[name='reply[is_internal]']:checked").val() === 'true';
    var task = this.selectedTask();

    var message;
    if(isInternal) {
      message = task.firstNotSmsMessage();
    } else {
      var firstNotInternalMessage = task.firstNotInternalNotSmsMessage();
      if (firstNotInternalMessage) {
        message = firstNotInternalMessage;
      } else {
        message = task.firstNotSmsMessage();
      }
    }

    var from = message.from === undefined ? '' : message.from.replace('<', '').replace('>', '');
    message = message.description();
    message = message.replaceAll('<br />', '<br />> ').replaceAll('\n', '<br />> ');
    message = "<br />" + from + ' ' + moment(message.createdAt).format('DD.MM.YYYY HH:mm') + " wrote: <br /><br />> " + message;

    var descriptionInput = form.find('[name="reply[description]"]');
    var oldDescription = descriptionInput.val();
    descriptionInput.val(oldDescription + '\n\n' + message);
    var formData = new FormData(form[0]);
    descriptionInput.val();
    this.isReplyEmailSending(true);
    var self = this;
    task.replyFormData(formData).done(function(){
      self._emailMessageSent();
      self.onChangeTaskState(); 
    });
    
  };

  Tasks.prototype.showReplyEmailSubmitBut = function () {
    if (!this.isReplyEmailSending()) {
      return true;
    } else {
      return false;
    }
  },
  Tasks.prototype.onRestartTask = function () {
    this.selectedTask().restart();
  };
  Tasks.prototype._emailMessageSent = function () {
    this.isReplyEmailSending(false);
    this.onCancelEmail();
    // Set the latest message as the selected one
    this.selectedMessage(this.selectedTask().messages()[0]);
  };

  Tasks.prototype.onRejectClose = function () {
    this._hideResultModal();
  };

  Tasks.prototype.onConfirmClose = function () {
    this.selectedTask().close(this.selectedResult()).done(this._hideResultModal.bind(this));
  };

  Tasks.prototype.onFooterButtonClick = function (target) {
    var self = this;

    if (target === 'home') {
      // Reset all filters
      this.filter(new FilterStore());
      this.filter().selectedServiceChannels(ko.utils.arrayMap(this.serviceChannels(), function (sc) {
        return sc.id;
      }));
      // Force refilter after data has been set
      this.filter.notifySubscribers();
    } else if (target === 'filter') {
      this.filteringActive(true);
      $('#filter-modal').modal('show');
    } else if (target === 'bookmarks') {
      // Reset filters and show assigned
      this.filter(new FilterStore());
      this.filter().selectedCategories(['assigned_to_me']);
    } else if (target === 'settings') {
      api.reloadUserData().success(function () {
        var apiCurrentUser = api.currentUser;
        apiCurrentUser.signature = apiCurrentUser.signature.split('<br>').join('\n');
        self.currentUser(apiCurrentUser);
        self.appSettingsActive(true);
        $('#app-settings-modal').modal('show');
      })
    }
  };

  Tasks.prototype.onCancelChangeTaskState = function () {
    $("#change-task-state-modal").modal("hide");
    this.changeTaskStateMessage(null);
  };

  Tasks.prototype.onChangeTaskState = function () {
    var task = this.selectedTask();
    var message = new Message({
      task_id: task.id
    });
    this.changeTaskStateMessage(message);
    $("#change-task-state-modal").modal("show");
  };

  Tasks.prototype.onConfirmChangeTaskState = function (data, event) {

    var task = this.selectedTask();
    var form = $(event.target).closest('form');
    var state = form.find('[name="task[state]"]:checked').val();
    var self = this;
    task.changeStateEvent(state, function(){
      self.onCancelChangeTaskState();
    })
  };

  return new Tasks();
});
