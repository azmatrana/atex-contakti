

Views.Customer = function(task) {
  "use strict";

  var self = this;

  this.task = ko.observable(task);
  this.customer = ko.observable(null);

  this.customerTaskNote = ko.observable(null);
  this.customerReadyTaskNote = ko.observable(null);
  this.customerTasks = ko.observableArray([]);
  this.customerReadyTasks = ko.observableArray([]);
  this.customerSearchResults = ko.observableArray([]);
  this.companySearchResults = ko.observableArray([]);
  this.customerFormDisabled = ko.observable(false);
  this.customerLoading = ko.observable(false);
  this.customerTasksLoading = ko.observable(false);
  this.customerEmailSearchResultsShow = ko.observable(false).extend({ rateLimit: 200});
  this.customerSearchInProgress = ko.observable(false);

  this.companySearchResultsShow = ko.observable(false).extend({ rateLimit: 200});
  this.companySearchInProgress = ko.observable(false);
  this.newCustomer = ko.observable({});
  this.newCustomerTaskNote = ko.observable({});
  this.newCustomerReadyTaskNote = ko.observable({});
  self.areTasksFetched = false;
  self.areReadyTasksFetched = false;
  this.taskNoteEditMode = ko.observable(null);
  this.taskNoteReadOnlyMode = ko.observable(null);
  this.readyTaskNoteEditMode = ko.observable(null);
  this.readyTaskNoteReadOnlyMode = ko.observable(null);

  this.refreshTasks = function (data) {
    if (_.isObject(data) && data.task && self.customer() && self.customer().id === data.task.customer_id){
      var foundInTasks = false;
      _.forEach(self.customerTasks(), function (task) {
        if (!task)
          return;
        if (task.id === data.task.id) {
          foundInTasks = true;
          if (data.task.state === 'ready') {
            self.customerTasks.remove(task);
          } else {
            var showMessagesList = task.showMessagesList();
            var newTask = new Task(data.task);
            newTask.showMessagesList(showMessagesList);
            self.customerTasks.replace(task, newTask);
          }
        }
      });

      var foundInReadyTasks = false;
      _.forEach(self.customerReadyTasks(), function (task) {
        if (!task)
          return;
        if (task.id === data.task.id) {
          foundInReadyTasks = true;
          if (data.task.state !== 'ready') {
            self.customerReadyTasks.remove(task);
          } else {
            var showMessagesList = task.showMessagesList();
            var newTask = new Task(data.task);
            newTask.showMessagesList(showMessagesList);
            self.customerTasks.replace(task, newTask);
          }
        }
      });
      if (!foundInTasks && data.task.state !== 'ready') {
        self.customerTasks.unshift(new Task(data.task));
      }

      if (!foundInReadyTasks && data.task.state === 'ready') {
        self.customerReadyTasks.unshift(new Task(data.task));
      }
    }
  };

  this.enableTaskNoteEdit = function () {
    self.taskNoteEditMode(true);
    self.taskNoteReadOnlyMode(false)
  };

  this.enableReadyTaskNoteEdit = function () {
    self.readyTaskNoteEditMode(true);
    self.readyTaskNoteReadOnlyMode(false)
  };

  this.saveTaskNote = function () {
    if (_.isEmpty(self.customerTaskNoteSafe()))
      return;

    var method = 'PUT';
    var url = "customers/" + self.customerSafe().id + "/update_task_note";

    $.ajax({
      url: url,
      method: method,
      data: { note: self.customerTaskNoteSafe() },
      dataType: "json",
      error: function(data) {
        // if (_.isObject(data.responseJSON) && _.isObject(data.responseJSON.errors)) {
        //   for (var key in data.responseJSON.errors) {
        //     self.addWarningAlert(data.responseJSON.errors[key][0]);
        //     break;
        //   }
        // }
      },
      success: function(data) {
        var $savedAlert = $('.customer-task-note-saved-alert');
        $savedAlert.removeClass('hide');
        setTimeout(function () {
          $savedAlert.addClass('hide');
        }, 5000)
      }
    });
  };

  this.saveReadyTaskNote = function () {
    if (_.isEmpty(self.customerReadyTaskNoteSafe()))
      return;

    var method = 'PUT';
    var url = "customers/" + self.customerSafe().id + "/update_ready_task_note";

    $.ajax({
      url: url,
      method: method,
      data: { note: self.customerReadyTaskNoteSafe() },
      dataType: "json",
      error: function(data) {
        // if (_.isObject(data.responseJSON) && _.isObject(data.responseJSON.errors)) {
        //   for (var key in data.responseJSON.errors) {
        //     self.addWarningAlert(data.responseJSON.errors[key][0]);
        //     break;
        //   }
        // }
      },
      success: function(data) {
        var $savedAlert = $('.customer-ready-task-note-saved-alert');
        $savedAlert.removeClass('hide');
        setTimeout(function () {
          $savedAlert.addClass('hide');
        }, 5000)
      }
    });
  };

  this.clearTaskNote = function () {
    if (self.customerTaskNote()) {
      self.customerTaskNote(_.clone(self.initialCustomerNote));
    }
    self.newCustomerTaskNote({});
  };

  this.clearReadyTaskNote = function () {
    if (self.customerReadyTaskNote()) {
      self.customerReadyTaskNote(_.clone(self.initialCustomerReadyNote));
    }
    self.newCustomerReadyTaskNote({});
  };

  this.customerSafe = ko.computed(function() {
    if (self.customer())
      return self.customer();
    return self.newCustomer();
  }).extend({ rateLimit: 200 });

  this.customerTaskNoteSafe = ko.computed(function() {
    if (self.customerTaskNote())
      return self.customerTaskNote();
    return self.newCustomerTaskNote();
  }).extend({ rateLimit: 200 });

  this.customerReadyTaskNoteSafe = ko.computed(function() {
    if (self.customerReadyTaskNote())
      return self.customerReadyTaskNote();
    return self.newCustomerReadyTaskNote();
  }).extend({ rateLimit: 200 });


  this.emailInputChanged = function(d, e) {
    self.searchForCustomers( self.customerSafe().email );
    return true; // For default behavior
  };

  this.getCustomerInformation = function() {
    if (self.customer()) // Don't load if already loaded
      return;

    $.ajax({
      url: "customers/load_customer_by_task_id",
      data: {q: self.task().id},
      dataType: 'json',
      beforeSend: function() {
        self.customerLoading(true);
      },
      success: function(customer) {
        if (customer) {
          self.customer( new CustomerDecorator(customer) );
        }
      },
      complete: function() {
        self.customerLoading(false);
      }
    });
  };

  this.clearVariables = function() {
    self.initialCustomer = null;
    self.customer(null);
    self.newCustomer({});
    self.newCustomerTaskNote({});
    self.newCustomerReadyTaskNote({});
    self.customerTasks.removeAll();
    self.customerReadyTasks.removeAll();
    self.customerSearchResults.removeAll();
    self.isReadyTasksFetched = false;
  };

  this.resetForm = function () {
    if (self.customer()) {
      self.customer(_.clone(self.initialCustomer));
    }
    self.newCustomer({});
  };

  this.saveCustomer = function(data,event) {
    if (_.isEmpty(self.customerSafe()))
      return;
    var url, method;
    // Check if at least email or phone
    if (!self.customerSafe().id) {
      url = "customers";
      method = 'POST';
    } else {
      url = "customers/" + self.customerSafe().id;
      method = 'PUT';
    }

    $.ajax({
      url: url,
      method: method,
      data: { customer: self.customerSafe() },
      dataType: "json",
      error: function(data) {
        if (_.isObject(data.responseJSON) && _.isObject(data.responseJSON.errors)) {
          for (var key in data.responseJSON.errors) {
            self.addWarningAlert(data.responseJSON.errors[key][0]);
            break;
          }
        }
      },
      success: function(data) {
        self.removeWarningAlert();
        var $savedAlert = $('.customer-saved-alert');
        $savedAlert.removeClass('hide');
        setTimeout(function () {
          $savedAlert.addClass('hide');
        }, 5000)
      }
    });
  };


  this.deleteCustomer = function(data,event) {
    if (_.isEmpty(self.customerSafe()))
      return;
    var url, method;
    if (self.customerSafe().id) {
      url = "customers/" + self.customerSafe().id;
      method = 'delete';
    }

    $.ajax({
      url: url,
      method: method,
      data: { customer: self.customerSafe() },
      dataType: "json",
      error: function(data) {
        if (_.isObject(data.responseJSON) && _.isObject(data.responseJSON.errors)) {
          for (var key in data.responseJSON.errors) {
            self.addWarningAlert(data.responseJSON.errors[key][0]);
            break;
          }
        }
      },
      success: function(data) {
        if (self.customer()) {
          self.customer(_.clone(null));
        }
        self.newCustomer({});
        if($('#super_search_input')){
          $('#super_search_input').val('').attr("is_deleted",'true');
        }
        var $deletedAlert = $('.customer-deleted-alert');
        $deletedAlert.removeClass('hide');
        setTimeout(function () {
          $deletedAlert.addClass('hide');
        }, 5000)
        // $(".contact-card-modal-dialog .close").click()
      }
    });
  }

  this.addWarningAlert = function (text) {
    var $warningAlert = $('.customer-warning-alert');
    $warningAlert.removeClass('hide');
    $warningAlert.text(text);
  };

  this.removeWarningAlert = function () {
    var $warningAlert = $('.customer-warning-alert');
    $warningAlert.addClass('hide');
  };

  this.removeCustomer = function() {
    if (!self.task().id)
      return;

    var deleteButton = $("#customer-delete-button", $("form#new_customer"));

    $.ajax({
      url: "customers/destroy_task_reference",
      data: {q: self.task().id},
      dataType: "json",
      beforeSend: function() {
        self.customerLoading(true);
        deleteButton.button("loading");
      },
      success: function() {
        self.customer(null);
        self.customerTasks([]);
      },
      complete: function() {
        self.customerLoading(false);
        deleteButton.button("reset");
      }
    });
  };

  this.loadCustomerTasks = function() {
    if (!self.customer() || !self.customer().id)
      return;

    $.ajax({
      url: "tasks/get_customer_tasks",
      data: {
        customer_id: self.customer().id,
        offset: self.customerTasks().length
      },
      dataType: 'json',
      beforeSend: function() {
        self.customerTasksLoading(true);
      },
      success: function(tasks) {
        if (tasks.length < 30)
          self.areTasksFetched = true;
        _.forEach(tasks, function(task_object) {
          self.customerTasks.push( new Task(task_object) );
        });
        self.customerTasks.sort(function (left, right) { // Sort by date created
          return right.id == left.id ? 0
            : (right.id < left.id ? -1 : 1);
        });
      },
      complete: function() {
        self.customerTasksLoading(false);
      }
    });
  };

  this.loadCustomerReadyTasks = function() {
    if (!self.customer() || !self.customer().id)
      return;

    $.ajax({
      url: "tasks/get_customer_ready_tasks",
      data: {
        customer_id: self.customer().id,
        offset: self.customerReadyTasks().length
      },
      dataType: 'json',
      beforeSend: function() {
        self.customerTasksLoading(true);
      },
      success: function(tasks) {
        if (tasks.length < 30)
          self.areReadyTasksFetched = true;
        _.forEach(tasks, function(task_object) {
          self.customerReadyTasks.push( new Task(task_object) );
        });
        self.customerReadyTasks.sort(function (left, right) { // Sort by date created
          return right.id == left.id ? 0
            : (right.id < left.id ? -1 : 1);
        });
      },
      complete: function() {
        self.customerTasksLoading(false);
      }
    });
  };

  this.customerTaskClicked = function(result) {
    var tempArray = self.customerTasks();
    _.forEach(tempArray, function(data) {
      if (result === data)
        data.contentHidden = !data.contentHidden;
    });

    // Refresh array
    self.customerTasks([]);
    self.customerTasks(tempArray);
  };

  this.customerSearchResultClicked = function(customerJsonModel) {
    self.customer( customerJsonModel );
    self.customerSearchResults([]);
  };

  this.customerSearchFieldFocusLost = function() {
    setTimeout(function(){ self.customerSearchResults([]); }, 200);
  };

  this.searchForCustomers = function(search_string) {
    if (!search_string || search_string.length < 3)
      return;

    $.ajax({
      url: 'customers/search',
      data: {q: search_string},
      dataType: 'json',
      beforeSend: function() {
        self.customerSearchInProgress(true);
      },
      success: function(customers_array) {
        self.customerSearchResults([]);
        _.forEach(customers_array, function(customer) {
          self.customerSearchResults.push( new CustomerDecorator(customer) );
        });
        self.customerSearchResults.sort(function(left, right) { // Sort by id
          return left.id == right.id ? 0
                                     : (left.id < right.id ? -1 : 1);
        });
      },
      complete: function() {
        self.customerSearchInProgress(false);
      }
    });
  };

  this.companySearchResultClicked = function(companyJsonModel) {
    self.customer().companyName(companyJsonModel.name);
    self.customer().companyId(companyJsonModel.id);
    self.companySearchResults([]);
  };

  this.removeCompanyFromModel = function() {
    self.customer().companyName("");
    self.customer().companyId("");
  };

  this.companySearchFieldFocusLost = function() {
    setTimeout(function(){ self.companySearchResults([]); }, 200);
  };

  this.companyInputChanged = function() {
    self.searchForCompanies(self.customer().companyName());
  };

  this.searchForCompanies = function(search_string) {
    if (!search_string || search_string.length < 3)
      return;

    $.ajax({
      url: 'customer_companies/search',
      data: {q: search_string},
      dataType: 'json',
      beforeSend: function() {
        self.companySearchInProgress(true);
      },
      success: function(companies_array) {
        self.companySearchResults([]);
        _.forEach(companies_array, function(company) {
          self.companySearchResults.push(company);
        });
        self.companySearchResults.sort(function(left, right) { // Sort by id
          return left.id == right.id ? 0
                                     : (left.id < right.id ? -1 : 1);
        });
      },
      complete: function() {
        self.companySearchInProgress(false);
      }
    });
  };

  this.loadCustomerById = function(customerId) {
      if (!customerId) {
        return;
      }

      $.ajax({
        url: "customers/" + customerId,
        dataType: 'json',
        beforeSend: function() {
          self.customer(null);
          self.customerLoading(true);
        },
        success: function(customer) {
          if (customer) {
            self.customer(customer);
            self.initialCustomer = _.clone(customer);
            self.customerTaskNote(customer.task_note);
            self.initialCustomerNote = _.clone(customer.task_note);
            if (customer.task_note) {
              self.taskNoteEditMode(false);
              self.taskNoteReadOnlyMode(true)
            } else {
              self.taskNoteEditMode(true);
              self.taskNoteReadOnlyMode(false);
            }
            self.customerReadyTaskNote(customer.ready_task_note);
            self.initialCustomerReadyNote = _.clone(customer.ready_task_note);
            if (customer.ready_task_note) {
              self.readyTaskNoteEditMode(false);
              self.readyTaskNoteReadOnlyMode(true)
            } else {
              self.readyTaskNoteEditMode(true);
              self.readyTaskNoteReadOnlyMode(false);
            }
            // if (_.isArray(customer.tasks)) {
            //   _.forEach(customer.tasks, function (task) {
            //     self.customerTasks.push(task)
            //   });
            // }
            self.loadCustomerTasks();
            self.loadCustomerReadyTasks();
          }
        },
        complete: function() {
          self.customerLoading(false);
        }
      });
  };

  var $customerTasksContainer = $('#customer-tasks-container');
  $customerTasksContainer.scroll(function () {
    if ($customerTasksContainer.scrollTop() + $customerTasksContainer.innerHeight() >= $customerTasksContainer[0].scrollHeight) {
      if (!self.areTasksFetched) {
        self.loadCustomerTasks();
      }
    }
  });

  var $customerReadyTasksContainer = $('#customer-ready-tasks-container');
  $customerReadyTasksContainer.scroll(function () {
    if ($customerReadyTasksContainer.scrollTop() + $customerReadyTasksContainer.innerHeight() >= $customerReadyTasksContainer[0].scrollHeight) {
      if (!self.areReadyTasksFetched) {
        self.loadCustomerReadyTasks();
      }
    }
  });

  var $companyModal = $('#company_modal');
  var $settingTabLink = $('.widget-tabs a[href="#account-settings"]');
  // $companyModal.on('shown.bs.modal', function (e) {
  // });

  $companyModal.on('hidden.bs.modal', function (e) {
    $settingTabLink.tab('show');
    self.clearVariables();
    self.removeWarningAlert();
  });

};
