Views.TimeTracker = function (task) {
  var self = this;
  this.trackerValidated = ko.observable(false);
  this.trackerObject = ko.observable(null);
  this.customers = ko.observableArray([]);
  this.customer = ko.observableArray(null);
  this.project = ko.observableArray(null);
  this.activity = ko.observableArray(null);
  this.projects = ko.observableArray([]);
  this.activities = ko.observableArray([]);
  this.trackerName = ko.observable("");
  this.activeTracker = ko.observableArray(null);
  this.allTasks = ko.observableArray([]);
  this.selectedTaskId = ko.observable(null);
  this.activeTrackerDatabaseData = ko.observableArray([]);
  this.comparedData = ko.observableArray([]);
  this.customerName = ko.observable("")
  this.url = ko.observable("");
  this.checkTracker = ko.observable("")
  this.tracker_email = ko.observable("")
  this.tracker_auth_token = ko.observable("")
  this.task = task;
  this.setTimeOut = {}


  this.authHeaders = function () {
    return {
      'X-AUTH-USER': self.tracker_email(),
      'X-AUTH-TOKEN': self.tracker_auth_token(),
    }
  }

  this.getCustomerList = function () {
    self.disableTrackerItem();
    $.ajax({
      type: "GET",
      dataType: 'json',
      url: self.url() + "/api/customers",
      headers: self.authHeaders(),
      success: function (data) {
        self.enableTrackerItem();
        self.customers.destroyAll()
        _.forEach(data, function (cust) {
          self.customers.push(cust);
        });
      }
    })
  }

  this.filteredCustomers = ko.computed(function () {
    return self.customers().sort(function(a,b) {
      var x = a.name.toLowerCase();
      var y = b.name.toLowerCase();
      return x < y ? -1 : x > y ? 1 : 0;
    });
  });

  this.getProjectList = async function () {
    self.disableTrackerItem();
    await $.ajax({
      type: "get",
      dataType: 'json',
      url: self.url() + "/api/projects",
      headers: self.authHeaders(),
      success: function (data) {
        self.enableTrackerItem();
        self.projects.destroyAll()
        _.forEach(data, function (proj) {
          self.projects.push(proj);
        });
      }
    })
  }


  this.filteredProjects = ko.computed(function () {
    return self.projects().filter(function (obj) {
      return (obj.customer == self.customer());
    }).sort(function(a,b) {
      var x = a.name.toLowerCase();
      var y = b.name.toLowerCase();
      return x < y ? -1 : x > y ? 1 : 0;
    });
  })


  this.getActivitiesList = async function () {
    self.disableTrackerItem();
    await $.ajax({
      type: "get",
      dataType: 'json',
      url: self.url() + "/api/activities",
      headers: self.authHeaders(),
      success: function (data) {
        self.enableTrackerItem();
        self.activities.destroyAll()
        _.forEach(data, function (activity) {
          self.activities.push(activity);
        });
      }
    });
  }

  this.filteredActivities = ko.computed(function () {
    return self.activities().filter(function (obj) {
      return (obj.project == self.project() || obj.project == null);
    }).sort(function(a,b) {
      var x = a.name.toLowerCase();
      var y = b.name.toLowerCase();
      return x < y ? -1 : x > y ? 1 : 0;
    });
  })

  this.disable_controlls = ko.computed(function () {
    return !( self.customer() && self.project() && self.activity() )
  })

  self.formDetails = async function () {
    self.customers.destroyAll()
    self.projects.destroyAll()
    self.activities.destroyAll()
    self.getCustomerList()
    await [self.getProjectList(), self.getActivitiesList()]
  }

  this.addActiveTrackerToDatabase = function () {
    console.log('addThisToDatabase', self.activeTracker())
    if (self.activeTracker()) {
      self.disableTrackerItem();
      $.ajax({
        type: 'POST',
        url: '/api/v1/create_tracker_detail',
        data: `tracker_detail[tracker_id]=${self.activeTracker().id}`,
        dataType: 'json',
        success: function () {
          self.enableTrackerItem();
          console.log('Tracker')
        }
      })
    } else {
      return
    }
  }

  this.getTask = function(){
    self.disableTrackerItem();
    $.ajax({
      type: 'GET',
      url: '/api/v1/tasks',
      dataType: 'json',
      success: function(data){
        self.enableTrackerItem();
        self.allTasks.push(data)
        console.log('TrackerTask',self.allTasks())
      }
    })
  }

  function get_elapsed_time_string(total_seconds) {
    function pretty_time_string(num) {
      return (num < 10 ? "0" : "") + num;
    }

    let hours = Math.floor(total_seconds / 3600);
    total_seconds = total_seconds % 3600;
    let minutes = Math.floor(total_seconds / 60);
    total_seconds = total_seconds % 60;
    let seconds = Math.floor(total_seconds);
    hours = pretty_time_string(hours);
    minutes = pretty_time_string(minutes);
    seconds = pretty_time_string(seconds);
    let currentTimeString = hours + ":" + minutes;// + ":" + seconds;
    return currentTimeString;
  }

  let clearTime;
  let elapsed_seconds = 0;

  function stopTimer() {
    clearInterval(clearTime);
  }

  function resetTime() {
    elapsed_seconds = 0;
  }

  function runTimer() {
    clearTime = setInterval(function () {
      elapsed_seconds = elapsed_seconds + 1;
      $('#pauseTimeTracker #duration').html(get_elapsed_time_string(elapsed_seconds));
    }, 1000);
  }

  this.getData = function () {
    self.disableTrackerItem();
    $.ajax({
      type: 'GET',
      url: '/api/v1/users/get_kimai_detail',
      datatype: 'json',
      success: function (data) {
        self.enableTrackerItem();
        self.tracker_email(data.credentials.tracker_email);
        self.tracker_auth_token(data.credentials.tracker_auth_token);
        self.url(data.tracker_url);
        
        if (self.tracker_email().length === 0) {
          $('#startTimeTracker').hide()
        }
        setTimeout(function () {
          self.validateApiUrl(self.getActiveTracker)
        }, 3000);
      }
    })
  }

  this.validateApiUrl = function (cb=null) {
    self.disableTrackerItem();
    $.ajax({
      type: 'GET',
      url: self.url() + "/api/ping",
      contentType: "application/json",
      headers: self.authHeaders(),
      success: function (data) {
        self.enableTrackerItem();
        self.trackerValidated(true);
        $('#startTimeTracker').show()
        console.log("company", data)
        if (cb)
        {
          cb();
        }
      },
      error: function () {
        $('#startTimeTracker').hide()
      }
    })
  }

  this.getActiveTracker = function () {
    self.disableTrackerItem();
    $.ajax({
      type: 'GET',
      url: self.url() + '/api/timesheets/active',
      dataType: 'json',
      headers: self.authHeaders(),
      success: function (data) {
        if (data && data.length > 0)
        {
          let active = data[0];
          startElTimer(active);
          self.activeTracker(active);
        }
        else
        {
          self.enableTrackerItem();
        }
      }
    })
  }

  function getTimeDifference(start, end)
  {
    var startDate = new Date(x);
    var endDate = new Date();

    var diff = endDate.getTime() - startDate.getTime();
    var diffInSeconds = diff / 1000;
    return diffInSeconds;
  }


  self.showSuccess = function (success, selector) {
    $(selector).addClass("hide")
    clearTimeout(self.setTimeOut[selector]);
    if (success) {
      $(selector).removeClass("hide");
      $(selector).text(success);
      self.setTimeOut[selector] = setTimeout(function () {
        $(selector).addClass("hide")
      }, 5000);

    }
  };

  self.showErrors = function (error, selector) {
    $(selector).addClass("hide");
    clearTimeout(self.setTimeOut[selector]);
    if (error && error.length > 0) {
      $(selector).removeClass("hide");
      $(selector).text(error);
      self.setTimeOut[selector] = setTimeout(function () {
        $(selector).addClass("hide");
      }, 5000);
    }
  }

  self.startTrackerForContactCustomer = async function (contact) {
    if (self.trackerValidated() == false) {
      return;
    }

    if (contact)
    {
      $.ajax({
        type: "GET",
        dataType: 'json',
        url: self.url() + `/api/customers?term=${contact}`,
        headers: self.authHeaders(),
        success: function (customers) {
          if (customers.length !== 0) {
            self.startRequestForCustomerContact(customers[0])
          } else {
            alert( I18n.t('time_tracker.customer_not_found_with_contact', {contact: contact}) )
          }
        }
      })
    }
  }

  self.startRequestForCustomerContact = async function (customer) {
    await [await self.getProjectList(), await self.getActivitiesList()]
    let project_id, activity_id;
    self.projects().forEach(project => {
      if (project.customer === customer.id && project.name.toLowerCase() === "call") {
        project_id = project.id;
      }
    })
    self.activities().forEach(activity => {
      if (activity.name.toLowerCase() === "call") {
        activity_id = activity.id;
      }
    });

    if (activity_id && project_id)
    {
      self.startTimerWithContact(project_id, activity_id)
    }
    else{
      alert( I18n.t('time_tracker.activity_and_project_must_present', {customer: customer.name}) )
    }

  }

  self.startTimerWithContact = function (project_id, activity_id) {
    let payLoad = {
      "project": project_id,
      "activity": activity_id,
    }
    $.ajax({
      type: 'POST',
      url: self.url() + '/api/timesheets',
      data: JSON.stringify(payLoad),
      dataType: 'json',
      contentType: 'application/json',
      headers: self.authHeaders(),
      success: function (data) {
        self.projects([])
        self.activities([])
        $('#pauseTimeTracker #duration').html('00:00');
        startElTimer(data);
      },
      error: function() {
        alert( I18n.t('time_tracker.error_timesheet') )
      }
    })
  }

  self.startRequest = function () {
    let projectID = self.project();
    let activityID = self.activity();
    let description = $("#tracker_description").val();
    let payLoad = {
      "project": parseInt(projectID),
      "activity": parseInt(activityID),
      "description": description,
    }
    self.disableTrackerItem();
    $.ajax({
      type: 'POST',
      url: self.url() + '/api/timesheets',
      data: JSON.stringify(payLoad),
      dataType: 'json',
      contentType: 'application/json',
      headers: self.authHeaders(),
      success: function (data) {
        $('#pauseTimeTracker #duration').html('00:00');
        startElTimer(data);
      },
      error: function (request) {
        let responseText = jQuery.parseJSON(request.responseText);
        let errorChild = responseText.errors.children
        if(responseText.code === 400){
          if (errorChild.project.errors?.length > 0) self.showErrors("Project:" + errorChild.project.errors[0] , "#timesheet_project_error");
          if (errorChild.activity.errors?.length > 0) self.showErrors("Activity:" + errorChild.activity.errors[0] , "#timesheet_activity_error");
        }
      }
    });
  }

  self.stopRequest = function () {
    let obj = self.trackerObject()
    console.log(obj)
    $('#pauseTimeTracker #duration').html(stopTimer());
    self.disableTrackerItem();
    $.ajax({
      type: 'PATCH',
      url: self.url() + `/api/timesheets/${obj.id}/stop`,
      dataType: 'json',
      contentType: 'application/json',
      headers: self.authHeaders(),
      success: function (data) {
        self.enableTrackerItem();
        $("#timer #restartTimeTracker").show();
        self.activeTracker(null);
        $("#pauseTimeTracker").addClass("disabled-content")
        // resetTime();
        // $('#pauseTimeTracker #duration').html(get_elapsed_time_string(elapsed_seconds));
      }
    })
  }

  self.restartRequest = function () {
    let obj = self.trackerObject()
    console.log(obj)
    self.disableTrackerItem();
    let payLoad = {
      copy: "description",
    }
    $.ajax({
      type: 'PATCH',
      url: self.url() + `/api/timesheets/${obj.id}/restart`,
      dataType: 'json',
      data: JSON.stringify(payLoad),
      contentType: 'application/json',
      headers: self.authHeaders(),
      success: function (data) {
        self.enableTrackerItem();
        self.trackerObject(data);
        $("#timer #restartTimeTracker").hide();
        $("#pauseTimeTracker").removeClass("disabled-content")
        // self.getActiveTracker();
        runTimer();
      }
    })
  }

  self.stopRequestAndReset = function () {
    let obj = self.trackerObject()
    console.log(obj)
    $('#pauseTimeTracker #duration').html(stopTimer());

    self.disableTrackerItem();
    $.ajax({
      type: 'PATCH',
      url: self.url() + `/api/timesheets/${obj.id}/stop`,
      dataType: 'json',
      contentType: 'application/json',
      headers: self.authHeaders(),
      success: function (data) {
        self.enableTrackerItem();
        $("#startTimeTracker").show();
        $("#timer #pauseTimeTracker").hide();
        $("#timer #stopTimeTracker").hide();
        $("#timer #restartTimeTracker").hide();
        $("#pauseTimeTracker").removeClass("disabled-content")
        $('#pauseTimeTracker #duration').html(resetTime());
        self.activeTracker(null);
      }
    })
  }

  self.disableTrackerItem = function(){
    $("#time-tracker-item-list").addClass("disabled-content");
    $("#tracker .modal-body").addClass("disabled-content");
  }

  self.enableTrackerItem = function(){
    $("#time-tracker-item-list").removeClass("disabled-content");
    $("#tracker .modal-body").removeClass("disabled-content");
  }

  function startElTimer(data)
  {
    self.enableTrackerItem();
    self.trackerObject(data)
    $("#startTimeTracker").hide();
    $("#time_tracker.modal").modal("hide")
    $("#timer #pauseTimeTracker").show();
    $("#timer #stopTimeTracker").show();
    $("#tracker_description").val('');
    timeFromTrackerObject(data.begin);
    runTimer();
  }

  function timeFromTrackerObject(time)
  {
    let begin = new Date(time);
    let now = new Date();

    let diff = now.getTime() - begin.getTime();
    let diffInSeconds = diff / 1000;
    elapsed_seconds = diffInSeconds;
  }

  if ( $("#time-tracker-item-list").length > 0 ){
    this.getData()
  }


}


Views.TimeTracker.prototype = Views;
