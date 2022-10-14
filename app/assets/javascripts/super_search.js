/**
 * Created by jussi on 12.5.2015.
 */

$(document).ready(function () {
  "use strict";


  var SuperSearch = new QueryThrottler(
    {
      timeout: 350,
      query: function (keyword, q_url, offset) {

        return $.ajax({
          url: q_url,
          data: {q: keyword, offset: offset},
          dataType: 'json',
          async: false
        });
      },
      beforeSend: function () {
        superSearchViewModel.searchingInProgress(true);
        // superSearchViewModel.superSearchResults.removeAll();
      },
      done: function (data) {
        _.forEach(data, function (res, key) {
          superSearchViewModel.superSearchResults.push(res);
        });

        superSearchViewModel.superSearchUpdateCurrentMark(); // update current property
        superSearchViewModel.searchingInProgress(false);
      }
    });

  function TaskResult(data) {
    var self = this;
    this.id = data.id;
    self.type = "task";
    self.current = false;
    self.creatorFullName = undefined;
    self.state = undefined;
    if (data.creator) {
      self.creatorFullName = data.creator.first_name + " " + data.creator.last_name;
    }
    if (data.state) {
      self.state = data.state;
    }
  }

  /**
   * KnockoutJS
   */
  function SuperSearchViewModel() {
    var self = this;
    this.queryString = ko.observable('');
    this.superSearchResults = ko.observableArray([]);
    this.searchRadioButton = ko.observable("search_all");
    this.searchUrlArchived = "/tasks/search_archived";
    this.searchUrlUnsolved = "/tasks/search_unsolved";
    this.searchUrlAll = "/tasks/super_search";
    this.getTaskByIdUrl = "/tasks/get_task_by_id";
    this.searchingInProgress = ko.observable(false);
    this.superSearchHasFocus = ko.observable(false);
    this.superSearchResultsShow = ko.observable(false);

    this.previousQuery = ko.observable("");
    this.superSearchUpdateCurrentMark = function() {
      var resultsArrayLength = self.superSearchResults().length;
      var selectedTask = window.userDashboardApp.selectedTask();

      if (selectedTask && selectedTask.id && resultsArrayLength > 0) {
        var resultaAsArray = self.superSearchResults();
        ko.utils.arrayForEach(resultaAsArray, function(searchResult) {
          searchResult.current = false; // Remove old property
          if (searchResult.id == selectedTask.id)
            searchResult.current = true;
        });

        // Dirty refresh
        self.superSearchResults([]);
        self.superSearchResults(resultaAsArray);
      }
    };
    let flag = 0;
    this.showData = function() {
      if(flag == 0) {
         self.superSearchResults.removeAll()
        SuperSearch.query(self.queryString(), self.searchUrlAll);
        self.superSearchResultsShow(true)
        flag = 1;
      } else {
        self.superSearchResultsShow(false)
        flag = 0;
      }
    }

    this.superSearchHasFocus.subscribe(function (value) {
      if (value) {
        if($('#super_search_input').attr('is_deleted') == "true"){
          $('#super_search_input').removeAttr('is_deleted');
          self.superSearchResultsShow(false)
        } else {
          self.superSearchResultsShow(true)
        }
      } else {
        setTimeout(function () {
          self.superSearchResultsShow(false)
        }, 200)
      }
    });

    this.queryString.subscribe(function () {
      self.sendRequest();
    });

    this.searchRadioButton.subscribe(function() {
      self.sendRequest();
    });

    this.sendRequest = function() {
      if (_.isEmpty(self.queryString())) {
        SuperSearch.abort();
        self.superSearchResults.removeAll();
      } else if (self.queryString().length > 2) {
        var query_url;
        if (self.searchRadioButton() === "search_all")
          query_url = self.searchUrlAll;
        else if (self.searchRadioButton() === "search_unsolved")
          query_url = self.searchUrlUnsolved;
        else if (self.searchRadioButton() === "search_archived")
          query_url = self.searchUrlArchived;
        if (superSearchViewModel.previousQuery() !== superSearchViewModel.queryString()) {
          superSearchViewModel.superSearchResults.removeAll();
          superSearchViewModel.previousQuery(superSearchViewModel.queryString())
        }
        SuperSearch.query(self.queryString(), query_url, self.superSearchResults().length);

      }
    };

    this.resultClicked = function (resultData) {
      // var selectedTask = window.userDashboardApp.selectedTask();
      // if (selectedTask && resultData && (resultData.id == selectedTask.id)) // Clicked on the same
      //   return;
      //
      // // If clicked on task
      // if (resultData.type == "task") {
      //   var resultId = resultData.id;
      //   // Search for task in UserDashboardApp.tasks() or return undefined if not in list
      //   var found = ko.utils.arrayFirst(window.userDashboardApp.tasks(), function(item) {
      //     return item.id == resultId;
      //   }) || undefined;
      //
      //   if (found)
      //     window.userDashboardApp.openTask(found);
      //   else {
      //     self.loadTaskById(resultId);
      //   }
      //   self.superSearchUpdateCurrentMark();
      // }
      // // Clicked on Customer
      // else if (resultData.type == "customer") {
        window.userDashboardApp.viewModels.customerModal.clearVariables();
        window.userDashboardApp.viewModels.customerModal.loadCustomerById(resultData.id);
        $("#company_modal").modal('toggle'); // Open modal
      // }
      // // Clicked on Company
      // else if (resultData.type == "company") {
      //   window.userDashboardApp.viewModels.companyModal.clearVariables();
      //   window.userDashboardApp.viewModels.companyModal.loadCompanyById(resultData.id);
      //   $("#company_modal").modal('toggle'); // Open modal
      // }
    };

    this.loadTaskById = function(taskId) {
      $.ajax({
        url: self.getTaskByIdUrl,
        data: {q: taskId},
        dataType: "json",
        beforeSend: function() {
          self.searchingInProgress(true);
        },
        success: function(task) {
          var decoratedTask = new Task(task[0]);
          window.userDashboardApp.openTask(decoratedTask);
          window.userDashboardApp.tasks.push(decoratedTask);
          self.superSearchUpdateCurrentMark();
        },
        complete: function() {
          self.searchingInProgress(false);
        }
      });
    };
    let mySuperSearchContainer = $('.super-search-results')[0]
    $('.super-search-results').scroll( function () {
      console.log("scrolling mySuperSearchContainer")
      if ( (mySuperSearchContainer.offsetHeight + mySuperSearchContainer.scrollTop + 100) >= mySuperSearchContainer.scrollHeight ) {
        console.log("------------ scrolled to end, value of !self.searchingInProgress() is = ", !self.searchingInProgress())
        if (!self.searchingInProgress()) {
          if (superSearchViewModel.previousQuery() !== superSearchViewModel.queryString()) {
            superSearchViewModel.superSearchResults.removeAll();
            superSearchViewModel.previousQuery(superSearchViewModel.queryString())
          }
          SuperSearch.query(self.queryString(), self.searchUrlAll, self.superSearchResults().length);
        }
      }
    });



  }

  // Binding
  var superSearchViewModel = new SuperSearchViewModel();
  window.superSearch = superSearchViewModel;

  // Spinner stuff
  // var opts = {};
  // _.extend(opts, UserDashboardApp.spinnerOpts);
  // _.extend(opts, {radius: 5, length: 5, lines: 9, width: 4, top: '33%', left: '43%'});

  // var superSearchSpinTarget = document.getElementById('super-search-bar');
  // var superSearchSpinner = new Spinner(opts);


  // ko.applyBindings(superSearchViewModel, $('#super-search-bar')[0]);

  // Stop super-search dropdown from closing when changing options
  $(".super-search-dropdown-menu").click( function(event) {
      event.stopPropagation();
  });

  $('body').on('click', '.super-search-result', function (event) {
    var self = this;
    var $self = $(self);
    _.forEach(superSearchViewModel.superSearchResults(), function (res, key) {
      if ($self.data('id') === res.id && $self.data('result_type') === res.result_type)
        superSearchViewModel.resultClicked(res);
    });
  })

  setTimeout(function () {
    $('.super-search-results').removeClass('hide')
  }, 500)


});
