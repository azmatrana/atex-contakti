
// TODO: Toomas - refactor this monster

Views.TaskContainer = function(task) {
  console.log(task());
  var self = this;

  this.task = task;

  this.customer = new Views.Customer(task);
  this.company = new Views.Company(task);
  this.orderModal = new Views.Order();
  this.showSmsForm = ko.observable(false);
  this.showInternalNoteForm = ko.observable(false);
  this.showForwardForm = ko.observable(false);
  this.showReplyForm = ko.observable(false);
  this.replyToMessage = ko.observable('');

  this.taskResult  = ko.observable('neutral');

  this.customerCompanyTabChanger = ko.observable("Customer"); // Select for change Customer or Company tabs

  this.onlyInternal = ko.observable(false);
  this.isReplyAll = ko.observable(false);

  this.cancelBackstepRequired = false;
  this.cancelBackstepState = '';
  this.playingId = ko.observable('');

  //this.timeTracker = new Views.TimeTracker(task)

  this.cancel = function() {
    if(!self.cancelBackstepRequired) {
      return;
    }

    if(self.task().state() != "open") {
      // Somebody else has changed the task state meanwhile, can't go back
      return;
    }

    if(['email', 'web_form', 'internal', 'chat', 'sms'].includes(self.task().data.media_channel)){
      self.task().saveDraft();
      if(self.cancelBackstepState == "new") {
        if(self.task().may_renew()) {
          self.cancelBackstepRequired = false;
          self.task().renew();
        } else {
        }
      } else if(self.cancelBackstepState == "open") {
      } else if(self.cancelBackstepState == "waiting") {
        if(self.task().may_pause()) {
          self.task().pause();
        } else {
        }
      }
    }
  };

  this.customerCompanyTabChanger.subscribe(function(newValue) {
    if (newValue == "Customer")
      self.customer.getCustomerInformation();
    else if (newValue == "Company")
      self.company.getCompanyInformation();
  });

  this.onTaskChange = function() {
    self.customerCompanyTabChanger("Customer");
    self.customer.clearVariables();
    self.company.clearVariables();
  };

  this.contactCardOpens = function() {
    self.customer.getCustomerInformation();
  };

  this.task.subscribe(function() {
    self.showSmsForm(false);
    if(self.task()) {
       self.showInternalNoteForm(self.task().noteBody() && self.task().noteBody().length > 0);
    }
    self.showForwardForm(false);
    self.showReplyForm(false);
  });

  this.serviceChannelChanged = function(a, event) {
    if (event.target.value !== '') {
      $('#move_to_agent').val('');
    }
  };

  this.agentChanged = function (a, event) {
    if (event.target.value !== '') {
      $('#move_to_service_channel').val('');
    }
  };

  this.followTask = function() {
    self.task().follow();
  };

  this.unfollowTask = function() {
    self.task().unfollow();
  };

  this.reopenTask = function() {
    self.task().restart();
  };

  this.lockTask = function() {
    self.task().lock();
  };

  this.unlockTask = function() {
    self.task().unlock();
  };

  this.archiveTask = function() {
    self.task().archive();
  };

  this.markAsDone = function() {
    self.task().close();
  };

  this.sendSmsClicked = function() {
    self.showSmsForm(true);
    self.task().start();
  };

  this.internalNoteClicked = function() {
    //self.showInternalNoteForm(!self.showInternalNoteForm());
    //could not figure out how to reference noteform enableEdit. Did an autoscroll instead
    if(self.showInternalNoteForm()){
      self.showInternalNoteForm(self.showInternalNoteForm());
    }
    else{
      self.showInternalNoteForm(!self.showInternalNoteForm());
    }
    $("html, body").animate({ scrollTop: 0 }, "slow");
  };

  this.downloadChatTxt = function(data) {
    var chat_hisotry = "";
    var arrayLength = data.messages().length
    for (var i = 0; i < arrayLength; i++) {
        console.log( data.messages()[i]);
        var chat_msg = data.messages()[i]
        if(chat_msg.type === "join"){
          chat_hisotry += chat_msg.from + " has joined the conversation" + "\n\n"
        }
        else{
          chat_hisotry += chat_msg.message + "\n"
          chat_hisotry += moment.utc(chat_msg.timestamp).local().format('D.M.YYYY HH.mm') + "\n"
          chat_hisotry += chat_msg.from + "\n\n"
        }
    }
    var element = document.createElement('a');
    element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(chat_hisotry));
    element.setAttribute('download', 'chat_history.txt');

    element.style.display = 'none';
    document.body.appendChild(element);

    element.click();

    document.body.removeChild(element);
    // $('.chat_box_option a')[0].href =  "data:text/plain;charset=UTF-8,"  + encodeURIComponent(now);
    // this.href = "data:text/plain;charset=UTF-8,"  + encodeURIComponent(now);
  }

  this.SendChatTxt = function(data){
  }

  this.printClicked = function(message) {
    var locale = window.UserDashboard.locale;
    messageUrl = "/" + locale + "/tasks/" + self.task().id + "/messages/" + message.id;
    var printTab = window.open(messageUrl, '_blank');
    printTab.focus();
  };

  this.forwardClicked = function(message) {
    self.replyToMessage(message);
    self.showForwardForm(true);
  };

  this.showReplyClicked = function(message) {
    self.onlyInternal(!self.task().firstNotInternalMessage());
    self.replyToMessage(self.task().lastMessage);
    self.showReplyForm(true);
    self.isReplyAll(false);
    document.getElementById('message-thread').scrollTop = 0;

    if(self.task().may_start()) {
      self.cancelBackstepRequired = true;
      self.cancelBackstepState = self.task().state();
      self.task().start();
    } else {
      self.cancelBackstepRequired = false;
    }
  };

  this.showReplyAllClicked = function(message) {
    self.onlyInternal(!self.task().firstNotInternalMessage());
    self.replyToMessage(self.task.lastMessage);
    self.showReplyForm(true);
    self.isReplyAll(true);
    document.getElementById('message-thread').scrollTop = 0;

    if(self.task().may_start()) {
      self.cancelBackstepRequired = true;
      self.cancelBackstepState = self.task().state();
      self.task().start();
    } else {
      self.cancelBackstepRequired = false;
    }
  };

  this.playAmr = function(path, id) {
    let self = this;
    if (window.amr_player && window.amr_player._isPlaying == true){
      window.amr_player.stop();
    }
    var amr = new BenzAMRRecorder();
    window.amr_player = amr;
    amr.initWithUrl(path).then(function() {
      amr.play();
      self.playingId(id);
    });
    amr.onStop(function () {
      self.playingId('');
    });
    amr.onEnded(function() {
      self.playingId('');
    })
  };

  this.stopAmr = function(path, id) {
    if (window.amr_player)
    {
      window.amr_player.stop();
    }
  }

  this.showDeleteModal = function() {
    $('#delete-task-modal').modal('show');
  };

  this.hideDeleteModal = function() {
    $('#delete-task-modal').modal('hide');
  };

  this.deleteTaskClicked = function() {
    self.hideDeleteModal();
    self.task().delete();
  };

  this.closeTaskClicked = function() {
    $('#task-panel-container').hide();
    $('#task-list-panel-container').toggleClass('hidden-xs');
    window.userDashboardApp.show_related_tickets(false);
    window.userDashboardApp.newMultipleTicketsFilter(null);
    $("#show_tickets_button").removeClass("active");
    window.userDashboardApp.enable_filter_domain(false);
    window.userDashboardApp.newDomainFilter(null);
    $("#domain_filter_button").removeClass("active-state");
  };

  this.clearInternalReply = function(data, event) {
    var form = $(event.target).closest('form');
    form.find('input').val('');
  };

  this.sendInternalReply = function() {
    var form = $(event.target).closest('form');
    form.trigger('submit.rails');
    self.clearInternalReply(data, event);
  };

  this.saveManagement = function(model, event) {
    var form = $(event.target).closest('form');
    setTimeout(function(){form.trigger('submit.rails')}, 50);
    $(event.target).closest('.modal').modal('hide');
  };

  this.cancelManagement = function(model, event) {
    if(task().managementDirty) {
      var form = $(event.target).closest('form');
      // need to bring the previous values back somehow.. ask the server to resend
      $('#cancel-manage').val('1');
      setTimeout(function(){form.trigger('submit.rails')}, 50);
    }
    $(event.target).closest('.modal').modal('hide');
  };

  this.saveTags = function() {
    $.ajax({
     url: '/api/v1/tags/task_skills',
     method: 'POST',
     data: {
       add: $('#tokenfield').val(),
       task_id: task().id
     },
     beforeSend: function() {
       $('#tokenfield').tokenfield('disable');
     },
     complete: function() {
       $('#tokenfield').tokenfield('enable');
     },
     success: function(response) {
       var generic_tags = [];
       _.forEach(response.tags, function(tag) {
         generic_tags.push(new GenericTag(tag, task()));
       });
       task().generic_tags(generic_tags);
       var skill_tags = [];
       _.forEach(response.skills, function(tag) {
         skill_tags.push(new Skill(tag, task()));
       });
       task().skills(skill_tags);
       $('#tokenfield').tokenfield('setTokens', []);
     }
    });
  };

  this.addTagsClicked = function() {
    var cache = {};

    $('#tokenfield').on('tokenfield:createdtoken', function(e) {
      var target = $(e.relatedTarget);
      var targetText = target.text();
      targetText = targetText.substring(0, targetText.length -1);

      $.each(window.userDashboardApp.tagList, function(index, item) {
        if (item.label === targetText && item.category === 'skills') {

          switch (item.priority) {
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
          target.css('background-color', '#FFFFFF');
          target.css('font-weight', 'bold');
        }
      });
    }).tokenfield({
      delimiter: [',', ' '],
      createTokensOnBlur: true,
      showAutocompleteOnFocus: true,
      autocomplete: {
        minLength: 0,
        delay: 100,
        source: window.userDashboardApp.tagList
      }
    });

    $('#tokenfield-tokenfield').focus();
  };


  this.showOtherTickets = function(){
    if (window.userDashboardApp.show_related_tickets() === false) {
      window.userDashboardApp.newMultipleTicketsFilter(this.parent.firstMessage().from);
      window.userDashboardApp.show_related_tickets(true);
      $("#same_email_filter_button").addClass("active-state");
    }
    else{
      window.userDashboardApp.show_related_tickets(false);
      window.userDashboardApp.newMultipleTicketsFilter(null);
      $("#same_email_filter_button").removeClass("active-state");
    }
  };

  this.filterTicketsByDomain = function(){
    if (window.userDashboardApp.enable_filter_domain() === false && this.parent.firstMessage().from) {
      window.userDashboardApp.newDomainFilter(this.parent.firstMessage().from.trim().split('@').pop());
      window.userDashboardApp.enable_filter_domain(true);
      $("#domain_filter_button").addClass("active-state");
    }
    else{
      window.userDashboardApp.enable_filter_domain(false);
      window.userDashboardApp.newDomainFilter(null);
      $("#domain_filter_button").removeClass("active-state");
    }
  }
};


Views.TaskContainer.prototype = Views;
