//= require filesize
//= require new_task_modal
//= require send_email_to_modal
//= require super_search
//= require_tree ./../templates
//= require ./../lodash.underscore
//= require ./models/skill
//= require ./models/flag
//= require ./models/generic_tag
//= require ./models/task
//= require ./models/filters
//= require ./models/sip_completed_call
//= require ./models/message
//= require ./view_models/base
//= require ./options
//= require_self
//= require ./chat
//= require ./service
//= require ./danthes
//= require ./decorators/customer_decorator
//= require ./decorators/task_decorator
//= require ./decorators/company_decorator
//= require ../sip/sip.min.js
//= require ../sip/sip_app.js
//= require ../sip/record.js
//= require ./../shared_view_models/base
//= require chat_utils.js


function UserDashboardApp() {
  var self = this;
  this.userId = null;
  this.media_channels = null;
  this.tasks = ko.observableArray().extend({rateLimit: 750});
  this.DesktopNotifications = false;
  this.danthes = null;
  this.selectedTask = ko.observable(null);
  this.prevSelectedTask = null;
  this.readyFilter = ko.observable(false);
  this.chatClient = null;
  this.DesktopNotifications = false;

  this.chosenAssociations = ko.observableArray();
  this.chosenStates = ko.observableArray();
  this.chosenServiceChannels = ko.observableArray();
  this.chosenMediaChannels = ko.observableArray();
  this.chosenSlas = ko.observableArray();
  this.filteredServiceChannelsByAgent = ko.observableArray();

  this.taskListSpinner = new Spinner(_.extend(UserDashboardOptions.spinnerOpts, {
    radius: 10,
    length: 15,
    lines: 12,
    width: 4
  })).spin($('#task-list-container')[0]);

  this.taskFilters = new Filters.TaskFilters();

  this.wsDisconnectedTimer = undefined;

  this.filteredServiceChannels = {};

  /* Filter service channels by media channel type */
  _.each([['email', 'MediaChannel::Email'], ['call', 'MediaChannel::Call'], ['internal', 'MediaChannel::Internal'], ['web', 'MediaChannel::WebForm'], ['chat', 'MediaChannel::Chat']], function (tuple) {
    var mcs = _.filter(UserDashboard.mediaChannels, function (mc) {
      return mc.type == tuple[1];
    });
    var scids = _.uniq(_.map(mcs, function (mc) {
      return mc.service_channel_id;
    }));
    self.filteredServiceChannels[tuple[0]] = UserDashboard.serviceChannels;
    // self.filteredServiceChannels[tuple[0]] = serviceChannels;
  });

  this.wsTransportUp = function () {
    if (typeof self.wsDisconnectedTimer != 'undefined') {
      clearTimeout(self.wsDisconnectedTimer);
    } else {
      /* $('#ws_disconnected').modal('hide'); */
    }
    self.wsDisconnectedTimer = undefined;
  };

  this.wsTransportDown = function () {
    if (typeof self.wsDisconnectedTimer == 'undefined') {
      self.wsDisconnectedTimer = setTimeout(function () {
        $('#ws_disconnected').modal({backdrop: 'static', keyboard: false});
        self.wsDisconnectedTimer = undefined;
      }, 120 * 1000);
    }
  };

  this.associationFilterChanged = function (a, event) {
    var assoc = ko.utils.arrayMap(event.currentTarget.selectedOptions, function (item) {
      return item.value
    });
    self.taskFilters.filters().multiAssignFilter().set(assoc);
    self.reFilter();
  };

  this.stateFilterChanged = function (a, event) {
    var assoc = ko.utils.arrayMap(event.currentTarget.selectedOptions, function (item) {
      return item.value
    });
    self.taskFilters.filters().multiStateFilter().set(assoc);
    self.reFilter();
  };

  this.serviceChannelFilterChanged = function (a, event) {
    var assoc = ko.utils.arrayMap(event.currentTarget.selectedOptions, function (item) {
      return item.value
    });
    self.taskFilters.filters().multiServiceChannelFilter().set(assoc);
    self.reFilter();
  };

  this.mediaChannelFilterChanged = function (a, event) {
    var assoc = ko.utils.arrayMap(event.currentTarget.selectedOptions, function (item) {
      return item.value
    });
    self.taskFilters.filters().multiMediaChannelFilter().set(assoc);
    self.reFilter();
  };

  this.slaFilterChanged = function (a, event) {
    var assoc = ko.utils.arrayMap(event.currentTarget.selectedOptions, function (item) {
      return item.value
    });
    if (assoc.indexOf('urgent') > -1) {
      self.taskFilters.filters().multiFlagFilter().set(['urgent']);
      assoc.splice(assoc.indexOf('urgent'));
    } else {
      self.taskFilters.filters().multiFlagFilter().set([]);
    }
    self.taskFilters.filters().multiSLAFilter().set(assoc);
    self.reFilter();
  };

  this.flagFilterChanged = function (a, event) {
    var assoc = ko.utils.arrayMap(event.currentTarget.selectedOptions, function (item) {
      return item.value
    });
    self.taskFilters.filters().multiFlagFilter().set(assoc);
    self.reFilter();
  };


  this.skillFilterChanged = function (a, event) {
    var assoc = ko.utils.arrayMap(event.currentTarget.selectedOptions, function (item) {
      return item.value
    });
    self.taskFilters.filters().multiSkillFilter().set(assoc);
    self.reFilter();
  };

  this.tagFilterChanged = function (a, event) {
    var assoc = event.target.value === '' ? [] : event.target.value.split(',');
    console.dir(assoc);
    self.taskFilters.filters().multiTagFilter().set(assoc);
    self.reFilter();
  };


  this.sortFilterChanged = function (filter) {
    self.taskFilters.filters().sortFilter().set(filter);
    self.reFilter();
  };
  this.show_related_tickets =  ko.observable(false);
  this.enable_filter_domain = ko.observable(false);

  this.tasks.subscribe(function () {
    self.reFilter();
    self.resizeToFit();
  });

  this.selectedTask.subscribe(function () {
    // When selected task changes, mark other tasks as not selected.

    if (self.prevSelectedTask !== null) {
      self.prevSelectedTask.selected(false);
    }

    if (self.selectedTask() !== null) {
      self.selectedTask().selected(true);
    }
    self.prevSelectedTask = self.selectedTask();

    // Do a resize to prevent message list exploding in height
    self.resizeToFit();
  });

  this.filteredTasks = ko.observable(self.taskFilters.filterArray(self.tasks()));
  this.filteredTasksForCounters = ko.observable(self.taskFilters.filterForCounters(self.tasks()));
  
  var timeTracker = new Views.TimeTracker();
  window.timeTrackerView = timeTracker;

  this.viewModels = {
    messageCounters: new Views.MessageCounters(this.filteredTasksForCounters, this.readyFilter, this),
    taskList: new Views.TaskList(this.filteredTasks),
    timeFilter: new Views.DateRangePicker(),
    searchBox: new Views.SearchBox(),
    taskContainer: new Views.TaskContainer(this.selectedTask),
    sipClientViewModel: new Views.SipClientViewModel(),
    markAsNewDialog: new Views.MarkAsNewDialog(this.selectedTask),
    markAsDoneDialog: new Views.MarkAsDoneDialog(this.selectedTask),
    smsMarkAsDoneDialog: new Views.SmsMarkAsDoneDialog(this.selectedTask),
    chatMarkAsDoneDialog: new Views.ChatMarkAsDoneDialog(),
    newTaskModal: window.newTaskModal,        // :D
    sendEmailModal: window.sendEmailModalViewModel,   // :D
    trainingViewModal: document.getElementById("training-modal") ? new Views.TrainingViewModel() : null,   // :D
    selectCompanyFilesModal: new Views.SelectCompanyFilesViewModel(),
    superSearch: window.superSearch,
    customerModal: new Views.Customer(),
    timeTracker: timeTracker,
    companyModal: new Views.Company(),
    notifications: new Views.Notifications(),
    sharedViews: {
      replyTemplatesModal: new SharedViews.ReplyTemplates(), // :D
      companyFiles: new SharedViews.CompanyFileViewModel(),
      basicTemplates: new SharedViews.BasicTemplates(),
      productsModel: new SharedViews.ProductsViewModel(),
      shipmentMethod: new SharedViews.ShipmentMethod(),
      vehicleDetailModal: new SharedViews.VehicleDetailModal(),
      thirdPartyTools: new SharedViews.ThirdPartyTools(),
    }

  };

  this.availableToUser = function (task) {

    if(self.is_assigned_to_user(task) == true) {
      if(self.is_assigned_to_current_user(task)) {
        return true;
      } else {
        return false;
      }
    }
    //const userServiceChannelIds = [...new Set(UserDashboard.current_user_service_channels.map(it => it.id))];
    // if (current_user_in_low_priority && task.data.priority == 0) {
    //   return true;
    // }

    // if(self.is_creator(task) === true) {
    //   return true
    // };

    if(task.data.open_to_all === false) {
      if([1,2,3].includes(task.data.priority)) {
        if((self.has_skills_matched_with_service_channels(task) === true) || (self.has_service_channel_access(task) === true && self.match_skills(task) === true)) {
          return true;
        } else {
          return false;
        }
      } else if(self.has_service_channel_access(task) === true && task.data.priority == 0) {
        return true;
      } else {
        return false
      }
    } else if(task.data.open_to_all === true) {
      if (task.data.priority === 3) {
        return true;
      } else if (task.data.priority === 2) {
        if(self.has_skills_matched(task) === true) {
          if(self.has_skills_matched_with_service_channels(task) === true) {
            return true;
          } else {
            return false;
          }
        } else if(self.has_location_service_channels_access(task) === true) {
          return true;
        } else {
          return false;
        }
      }
      else if (task.data.priority === 1) {
        if(self.has_skills_matched(task) === true) {
          if(self.has_skills_matched_with_service_channels(task) === true) {
            return true;
          } else {
            return false;
          }
        } else if(self.has_service_channel_access(task) === true) {
          return true;
        } else {
          return false;
        }
      }
      else if (task.data.priority === 0) {
        if(self.has_service_channel_access(task) === true) {
          return true;
        } else {
          return false
        }
      }
    } else {
      return false;
    }
  };

  this.is_assigned_to_user = function(task) {
    if(task.data.assigned_to_user_id == undefined || task.data.assigned_to_user_id === null){
      return false;
    } else {
      return true;
    }
  }

  this.is_assigned_to_current_user = function(task) {
    if(task.data.assigned_to_user_id === UserDashboard.currentUserId){
      return true;
    }
  }
  this.has_service_channel_access = function(task) {
    if(UserDashboard.current_user_service_channels.find(channel => channel.id === task.data.service_channel_id) != undefined) {
      return true;
    }
  };

  this.has_location_service_channels_access = function(task) {
    if(task.data.service_channel_agent_ids.includes(UserDashboard.currentUserId)) {
      return true;
    }
  };

  this.has_skills_matched_with_service_channels = function(task) {
    if(task.data.skills_matched_service_channel_agents.includes(UserDashboard.currentUserId)) {
      return true;
    }
  };

  this.has_skills_matched = function(task) {
    if(task.data.skills_matched_service_channel_agents.length > 0) {
      return true;
    } else {
      return false;
    }
  };

  this.is_creator = function(task) {
    if(UserDashboard.currentUserId === task.data.created_by_user_id) {
      return true;
    }
  };

  this.match_skills = function(task) {
    for (i=0; i < current_user_skills.length; i++) {
      for (j=0; j < task.data.skills.length; j++) {
        if (current_user_skills[i] === task.data.skills[j]) {
          return true;
        }
      }
    }
    return false;
  };

  this.reFilter = function (params) {
    var all_task = []
    if(params != undefined && params === 'test'){
      var count = 0;
      _.forEach(self.tasks(), function (task) {
        all_task.push(task)

      if(UserDashboard.current_user_service_channels.find(x => x.id === task.data.service_channel_id) === undefined && UserDashboard.currentUserId != task.data.assigned_to_user_id){
        delete self.tasks()[count];

      }
      count++;
      });
      self.filteredTasks(self.taskFilters.filterArray(self.tasks().filter(function(v){return v!==''})));
    }else{
      self.filteredTasks(self.taskFilters.filterArray(self.tasks()));
    }
    if(params != undefined && params === 'test'){
      self.tasks = ko.observableArray(all_task);
    }

    self.filteredTasksForCounters(self.taskFilters.filterForCounters(self.tasks()));
  };

  this.initialise = function (refresh) {
    var refresh = true == refresh;
    this.resizeToFit();

    $(window).resize(function () {
      self.resizeToFit();
    });

    var tasksFetched = false;
    var readyTasksFetched = false;
    $.ajax({
      url: 'tasks/get_tasks',
      dataType: 'json',
      error: function (error) {
        var r = jQuery.parseJSON(error.responseText);
      },
      success: function (tasks) {
        tasksFetched = true;
        if(refresh) {
          self.tasks.removeAll();
        }
        self.taskListSpinner.stop();
        _.forEach(tasks, function (data) {
          self.tasks.push(new Task(data));
        });

        // retain the selected task
        if(self.selectedTask()){
          var selectTask = ko.utils.arrayFilter(self.tasks(), function (task) {
            return task.id === self.selectedTask().id;
          });
          self.openTask(selectTask[0]);
        }

        if (readyTasksFetched)
          self.sortTasks();

        $.ajax({
          url: 'tasks/get_ready_tasks',
          dataType: 'json',
          success: function (tasks) {
            readyTasksFetched = true;
            if (tasks.length < 30) {
              self.viewModels.messageCounters.moreReady(false);
            }
            _.forEach(tasks, function (task) {
              self.tasks.push(new Task(task));
            });
            // Do we have to sort them? And how often?
            // Backend should return them already sorted by creation time?
            // Any new task received by danthes should be new ?
            // Actually fetching 'ready' tasks should trigger sorting?

            if (tasksFetched)
              self.sortTasks();
          }
        });
      }
    });
    // $.ajax({
    //   url: 'tasks/get_ready_tasks',
    //   dataType: 'json',
    //   success: function (tasks) {
    //     readyTasksFetched = true;
    //     if (tasks.length < 30) {
    //       self.viewModels.messageCounters.moreReady(false);
    //     }
    //     _.forEach(tasks, function (task) {
    //       self.tasks.push(new Task(task));
    //     });
    //     // Do we have to sort them? And how often?
    //     // Backend should return them already sorted by creation time?
    //     // Any new task received by danthes should be new ?
    //     // Actually fetching 'ready' tasks should trigger sorting?

    //     if (tasksFetched)
    //       self.sortTasks();
    //   }
    // });

    self.fetchTagList();

    this.viewModels.messageCounters.registerCallback('filterChanged', this.newStateFilter);
    this.viewModels.taskList.registerCallback('openTask', this.openTask);
    this.viewModels.timeFilter.registerCallback('filterChanged', this.newTimeFilter);
    this.viewModels.timeFilter.initialize();
    this.viewModels.searchBox.registerCallback('filterChanged', this.newSearchFilter);

    this.danthes = new UserDashboardApp.Danthes();
    this.danthes.initialise();

    this.chatClient = new UserDashboardApp.Chat();
    this.chatClient.initialise();

    this.initializeDesktopNotifications();
  };

  this.resizeToFit = function () {
    var getHeight = $(window).height();
    $('#message-thread').height(getHeight - 148);
//    $('#internal .message-thread').height(getHeight - 220);
    $('.inbox-preview:not(.height-auto)').height(getHeight - 200);
  };

  this.newStateFilter = function (newState) {
    if (newState == 'ready') {
      self.readyFilter(true);
    } else {
      self.readyFilter(false);
    }

    self.taskFilters.filters().stateFilter().set(newState);
    self.reFilter();

    // Manually trigger searchBox subscription
    self.viewModels.searchBox.stateChanged();
  };

  this.newTimeFilter = function (filter) {
    self.taskFilters.filters().timeFilter().set(filter);
    self.reFilter();
  };

  this.newSearchFilter = function (filter) {
    self.taskFilters.filters().searchFilter().set(filter);
    self.reFilter();
  };

  this.newMultipleTicketsFilter = function(filter){
    self.taskFilters.filters().multipleTicketsFilter().set(filter);
    self.reFilter();
  }

  this.newDomainFilter = function(filter){
    self.taskFilters.filters().domainFilter().set(filter);
    self.reFilter();
  }

  this.openTask = function (task) {
    task.onOpen();

    var all_serviceChannels = UserDashboard.serviceChannels;
    var all_agents = UserDashboard.agents;
    var serviceChannels = [];
    all_agents.forEach(obj => {
      all_serviceChannels.forEach(element => {
        for (var i = 0; i < element["agents"].length; i++) {
          if (obj.id == element["agents"][i].id){
            if (element.name != "Private Agent Channel") {
              serviceChannels.push(element);
            }
          }
        }
      });
    });
    let unique = [...new Set(serviceChannels)];
    // self.filteredServiceChannelsByAgent(UserDashboard.serviceChannels.filter(channel => channel.agents.findIndex(agent => agent.id == task.assigned_to_user_id()) > -1))
    self.filteredServiceChannelsByAgent(unique);
    self.selectedTask(task);
    self.viewModels.taskContainer.onTaskChange();
  };

  this.readyTaskCount = function () {
    var tasks = ko.utils.arrayFilter(self.tasks(), function (task) {
      return task.state() === 'ready';
    });
    return tasks.length;
  };

  this.isSorting = false;

  this.sortTasks = function () {
    if (self.isSorting) {
      return true;
    } else {
      self.isSorting = true;
      self.tasks.sort(function (left, right) {
        var priorityDiff = right.data.priority - left.data.priority;
        var dateA=new Date(right.data.created_at);
        var dateB=new Date(left.data.created_at);
        var dateDiff;
        if(left.data.priority == right.data.priority) {
          if(left.data.priority == 0)
            dateDiff = dateA - dateB
          else
            dateDiff = dateB - dateA
        }
        else {
          dateDiff = dateB - dateA
        }

        return priorityDiff || dateDiff;
      });

      // sort again to put urgent first:
      // self.tasks.sort(function(left, right) {
      //   // if(left.isUrgent() && right.isUrgent)  { return 0; }
      //   // if(left.isUrgent())                    { return -1; }
      //   // if(right.isUrgent())                   { return 1; }
      //   return 0;
      // });
      self.isSorting = false;
    }
  };

  this.tagList = [];

  this.fetchTagList = function () {
    $.getJSON('/api/v1/tags/company', function (data) {
      self.tagList = data;
    });
  }

  this.fetchMoreReadyTasks = $.debounce( 1000, true, function () {
    console.log('Fetching API')
    $.ajax({
      url: 'tasks/get_ready_tasks',
      dataType: 'json',
      data: {offset: self.readyTaskCount()},
      success: function (tasks) {
        if (tasks.length === 0) {
          self.viewModels.messageCounters.moreReady(false);
        }
        else {
          _.forEach(tasks, function (taskData) {
            self.tasks.push(new Task(taskData));
          });
          // self.sortTasks();
        }
      }
    });
  })

  this.initializeDesktopNotifications = function () {
    var self = this;
    var afterPermissionRequest = function (data) {
      if (data == "granted") {
        self.DesktopNotifications = true;
      }
    };

    if (notify.isSupported == false) {
      return;
    }

    var notifyval = notify.permissionLevel();
    if (notifyval == notify.PERMISSION_DEFAULT) {
      notify.requestPermission(afterPermissionRequest);
    } else if (notifyval == notify.PERMISSION_GRANTED) {
      this.DesktopNotifications = true;
    } else {
      alert("Desktop notifications disabled. Change your browser's settings if you want to see them.");
    }
  };
}


$(document).ready(function () {
  window.userDashboardApp = new UserDashboardApp();
  userDashboardApp.initialise();

  ko.bindingHandlers.includeDomElement = {
    init: function (element, valueAccessor, allBindingsAccessor, viewModel) {
      if (!valueAccessor().observable.element) {
        _.extend(valueAccessor().observable, {element: {}});
      }
      valueAccessor().observable.element[valueAccessor().value] = element;
    }
  };

  ko.components.register('forwardform-component', {
    viewModel: Views.ForwardForm,
    template: {element: 'task_messages_forward_form_template'}
  });

  ko.components.register('replyform-component', {
    viewModel: Views.ReplyForm,
    template: {element: 'task_messages_reply_form_template'}
  });

  ko.components.register('smsform-component', {
    viewModel: Views.SmsForm,
    template: {element: 'task_messages_sms_form_template'}
  });

  ko.components.register('note-component', {
    viewModel: Views.NoteForm,
    template: {element: 'note_template'}
  });

  ko.components.register('skill-tag-component', {
    viewModel: Views.SkillContainer,
    template: {element: 'skill_tag_template'}
  });

  ko.components.register('flag-tag-component', {
    viewModel: Views.FlagContainer,
    template: {element: 'flag_tag_template'}
  });

  ko.components.register('generic-tag-component', {
    viewModel: Views.GenericTagContainer,
    template: {element: 'generic_tag_template'}
  });

  ko.applyBindings(userDashboardApp, $('#knockout-main')[0]);
});

// Initialize moment locale
$(document).ready(function () {
  moment.locale(I18n.locale);
});

// New task modal dialog
$(document).ready(function () {
  "use strict";

  if (window.userSignature) {
    $('#task_messages_attributes_0_description').val("<br><br>" + window.userSignature);
  }

  // rich text field in new task modal
  var newTaskTextField = CKEDITOR.replace('task_messages_attributes_0_description', {
      language: I18n.currentLocale(),
      autogrow_maxHeight: 0,
      removePlugins: 'autogrow',
      resize_enabled: false
    }
    ),
    newTaskSave = $('a.new-task-save');

  $('#new_task_modal').on('shown.bs.modal', function (e) {
    $('#tags').tokenfield({
      autocomplete: {
        source: window.userDashboardApp.tagList,
        delay: 100
      },
      showAutocompleteOnFocus: true
    })
//      CKEDITOR.instances['task_messages_attributes_0_description'].execCommand('autogrow');
  });

  // new task media and service channel select box synchronisation
  $('#task_media_channel_id.media_channel').on("change", function () {
    var serviceChannelSelect = $('#task_service_channel_id.service_channel');
    serviceChannelSelect.empty();
    serviceChannelSelect.prepend($("<option></option>"));
    _.forEach(serviceChannelsByMediaChannel($(this).val()), function (channel) {
      serviceChannelSelect.append($("<option></option>").val(channel.id).text(channel.name));
    });
  });

  // Helper function
  function serviceChannelsByMediaChannel(name) {
    return _.filter(UserDashboard.serviceChannels, function (n) {
      return !!_.find(UserDashboard.mediaChannels, function (i) {
        return i.type === name && n.id === i.service_channel_id;
      });
    });
  }

  $('.new_task_service_channel, .new_task_title').on('change', function () {
    newTaskSave.attr(
      "disabled",
      !(!!$('.new_task_service_channel').val() &&
        !!$('.new_task_title').val())
    );
  });

  $('#new_task_link').click(function () {
    $('#task_type').val('internal');
    $('#task_messages_attributes_0_title').val('');
    // CKEDITOR.instances['task_messages_attributes_0_description'].setData('');
    if (window.userSignature) {
      CKEDITOR.instances['task_messages_attributes_0_description'].setData("<br><br>" + window.userSignature);
    } else {
      CKEDITOR.instances['task_messages_attributes_0_description'].setData("");
    }
  });

  // new task modal attachment buttons activity + renaming file field to make unique
  $('.fileupload-section button').on("click", function (e) {
    var clone = $(e.currentTarget).siblings('.fileupload.template').clone();
    clone.fileupload();
    var fileField = clone.find(".file-field");
    fileField.attr('name', fileField.attr('name').replace(/(.*\[)0(\]\[file\])/, "$1" + new Date().getTime() + "$2"));
    $(e.currentTarget).closest('.fileupload-section').append(clone.removeClass('hidden template').addClass('attachments'));
  });

  // Submit the form
  newTaskSave.on("click", function () {
    var form = $('#new_task'),
      description = newTaskTextField.getData();

    if (description == "") {
      alert('Please fill in a description.');
      return;
    } else {
      $('.new_task_description').val(description);
    }

    form.on("ajax:beforeSend", function () {
      newTaskSave.button('loading');
    });
    form.on("ajax:error", function () {

    });
    form.on("ajax:success", function () {
      $('.fileupload.attachments', self).remove();
    });
    form.on("ajax:complete", function (xhr, res) {
      var self = $(this);
      self.closest('.modal').modal('hide');
      $('input, select', self).not('.new-task-modal-languages').val('');
      newTaskTextField.setData('');
      $('.fileupload-section').find('.attachments').remove();
      newTaskSave.button('reset');
      newTaskSave.attr('disabled', true);
      window.lastCallRecordingBlob = undefined;
      window.userDashboardApp.viewModels.newTaskModal.resetAgents();
      window.userDashboardApp.viewModels.sipClientViewModel.slidePhone('close');
      document.getElementById("recordingTimer").classList.add('hide');
      document.getElementById("amr-play-record").classList.add('hide');
      document.getElementById("amr-down-record").classList.add('hide');
      // document.getElementById("afterStopButton").classList.add('hide');
      //$('#new-task-modal-dialog').data('new_task_modal_key').resetAgents(); // TODO: Remove this hack when shifting to Knockoutjs is complete
      // Removed and working? -Toomas
    });

    form.trigger('submit.rails');
  });
  window.userDashboardApp.reFilter();
  $('#sip_client_wrapper').removeClass('hide');
});

$( window ).load(function() {
  $('#new_sms_link').on("click", function () {
    $('#sms_templates_editor').find('form').trigger('reset');
    $('.alert.modal-alert').hide();
  });
});
