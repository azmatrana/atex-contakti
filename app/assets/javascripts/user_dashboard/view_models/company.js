

Views.Company = function(task) {
  "use strict";

  var self = this;

  this.task = task;
  this.company = ko.observable(null);
  this.companyLoading = ko.observable(false);
  this.companyTasksLoading = ko.observable(false);
  this.companyTasks = ko.observableArray([]);

  this.companySearchResults = ko.observableArray([]);
  this.companyNameSearchInProgress = ko.observable(false);
  this.companySearchResultsShow = ko.observable(false).extend({ rateLimit: 200});

  this.contactPersonSearchResult = ko.observableArray([]);
  this.contactPersonSearchInProgress = ko.observable(false);
  this.contactPersonSearchResultsShow = ko.observable(false).extend({ rateLimit: 200});

  this.companySafe = ko.computed(function() {
    if (self.company())
      return self.company();
    return {};
  }).extend({ rateLimit: 200 });


  this.getCompanyInformation = function() {
    if (self.company()) // Don't load if already loaded
      return;

    $.ajax({
      url: "customer_companies/load_customer_company_by_task_id",
      data: {q: self.task().id},
      dataType: 'json',
      beforeSend: function() {
        self.companyLoading(true);
      },
      success: function(company) {
        if (company) {
          self.company( new CompanyDecorator(company) );
        }
      },
      complete: function() {
        self.companyLoading(false);
      }
    });
  };

  this.clearVariables = function() {
    self.company(null);
    self.companyTasks([]);
    self.contactPersonSearchResult([]);
    self.companySearchResults([]);
  };

  this.saveCompany = function(data,event) {
    // Check all fields for company
    var customerCompanyForm = $(event.target).closest('form'),
        saveButton = $("#customer-company-save-button", customerCompanyForm),
        name = $("#customer_company_name", customerCompanyForm).val(),
        email = $("#customer_company_email", customerCompanyForm).val(),
        phone = $("#customer_company_phone", customerCompanyForm).val()
      ;

    if (!name || (!email && !phone)) {
      alert("Please fill in company name and at least email or phone");
      return;
    }

    customerCompanyForm.on("ajax:beforeSend", function () {
      self.companyLoading(true);
      saveButton.button("loading");
    });
    customerCompanyForm.on("ajax:error", function () {

    });
    customerCompanyForm.on("ajax:success", function (respData, company, respXhr) {
      if (company)
        self.company( new CompanyDecorator(company) );

      self.companyTasks([]);
    });
    customerCompanyForm.on("ajax:complete", function () {
      self.companyLoading(false);
      saveButton.button("reset");
    });

    customerCompanyForm.trigger("submit.rails");
  };

  this.removeCompany = function() {
    if (!self.task().id)
      return;

    var deleteButton = $("#customer-company-delete-button", $("form#new_customer_company"));

    $.ajax({
      url: "customer_companies/destroy_company_task_reference",
      data: {q: self.task().id},
      dataType: "json",
      beforeSend: function() {
        self.companyLoading(true);
        deleteButton.button("loading");
      },
      success: function() {
        self.company(null);
        self.companyTasks([]);
      },
      complete: function() {
        self.companyLoading(false);
        deleteButton.button("reset");
      }
    });
  };

  this.loadCompanyTasks = function() {
    if (!_.isEmpty(self.companyTasks()) || !self.company() || !self.company().id)
      return; // Exit if tasks are already loaded or there is no customer id (loading in progress or just empty)

    $.ajax({
      url: "customer_companies/load_tasks_by_customer_company_id",
      data: {q: self.company().id},
      dataType: 'json',
      beforeSend: function() {
        self.companyTasksLoading(true);
      },
      success: function(tasks) {
        self.companyTasks([]);
        _.forEach(tasks, function(task_object) {
          self.companyTasks.push( new TaskDecorator(task_object) );
        });
        self.companyTasks.sort( function(left, right) { // Sort by date created
          return right.id == left.id ? 0
                                         : (right.id < left.id ? -1 : 1);
        });
      },
      complete: function() {
        self.companyTasksLoading(false);
      }
    });
  };

  this.companyTaskClicked = function(result) {
    var tempArray = self.companyTasks();
    _.forEach(tempArray, function(data) {
      if (result === data)
        data.contentHidden = !data.contentHidden;
    });

    // Refresh array
    self.companyTasks([]);
    self.companyTasks(tempArray);
  };

  this.contactPersonFieldFocusLost = function() {
    setTimeout(function(){ self.contactPersonSearchResult([]); }, 200);
  };
  this.companySearchFieldFocusLost = function() {
    setTimeout(function(){ self.companySearchResults([]); }, 200);
  };

  this.contactPersonSearchResultClicked = function(contactPersonJsonModel) {
    self.company().contactPersonId(contactPersonJsonModel.id);
    self.company().contactPersonFirstName(contactPersonJsonModel.first_name);
    self.company().contactPersonLastName(contactPersonJsonModel.last_name);
    self.company().contactPersonEmail(contactPersonJsonModel.email);
    self.contactPersonSearchResult([]);
  };

  this.companySearchResultClicked = function(companyJsonModel) {
    self.company(companyJsonModel);
    self.companySearchResults([]);
  };

  this.searchForCompanies = function(search_string) {
    if (!search_string || search_string.length < 3)
      return;

    $.ajax({
      url: 'customer_companies/search',
      data: {q: search_string},
      dataType: 'json',
      beforeSend: function() {
        self.companyNameSearchInProgress(true);
      },
      success: function(companies_array) {
        self.companySearchResults([]);
        _.forEach(companies_array, function( company ) {
          self.companySearchResults.push( new CompanyDecorator(company) );
        });
        self.companySearchResults.sort(function(left, right) { // Sort by id
          return left.id == right.id ? 0
                                     : (left.id < right.id ? -1 : 1);
        });
      },
      complete: function() {
        self.companyNameSearchInProgress(false);
      }
    });
  };

  this.searchForContactPerson = function(search_string) {
    if (!search_string || search_string.length < 3)
      return;

    $.ajax({
      url: 'customers/search',
      data: {q: search_string},
      dataType: 'json',
      beforeSend: function() {
        self.contactPersonSearchInProgress(true);
      },
      success: function(customers_array) {
        self.contactPersonSearchResult([]);
        _.forEach(customers_array, function(customer) {
          self.contactPersonSearchResult.push( customer );
        });
        self.contactPersonSearchResult.sort(function(left, right) { // Sort by id
          return left.id == right.id ? 0
                                     : (left.id < right.id ? -1 : 1);
        });
      },
      complete: function() {
        self.contactPersonSearchInProgress(false);
      }
    });
  };

  this.companyInputChanged = function(d, e) {
    self.searchForCompanies( self.companySafe().name );
    return true; // For default behavior
  };

  this.contactPersonInputChanged = function(d, e) {
    self.searchForContactPerson( self.companySafe().contactPersonEmail() );
    return true; // For default behavior
  };

  this.removeContactPersonFromModel = function() {
    self.company().contactPersonId("");
    self.company().contactPersonFirstName("");
    self.company().contactPersonLastName("");
    self.company().contactPersonEmail("");
  };

  this.loadCompanyById = function(companyId) {
      if (!companyId) {
        return;
      }

      $.ajax({
        url: "customer_companies/get_customer_company_by_id",
        data: {q: companyId},
        dataType: 'json',
        beforeSend: function() {
          self.company(null);
          self.companyLoading(true);
        },
        success: function(company) {
          if (company) {
            self.company( new CompanyDecorator(company) );
          }
        },
        complete: function() {
          self.companyLoading(false);
        }
      });
  };

};
