Views.SipClientViewModel = function() {
  var self = this;

  this.companyAgents = ko.observableArray([]);
  this.lastAction    = ko.observable('');


  this.inDnd           = ko.observable(false);
  this.inTransfercalls = ko.observable(false);
  this.inFollowme      = ko.observable(false);
  this.inAcd           = ko.observable(false);
  this.customerFromCall = ko.observable({});

  this.customerFromCall = ko.observable({});

  this.customerId = ko.pureComputed(function() {
    if (!self.customerFromCall() && !self.customerFromCall().id) return;
    return self.customerFromCall().id;
  });


  this.callLogs      = ko.observable({});

  this.setLastAction = function(item){
    this.lastAction(item)
  }
  this.onCallSettings = function(){

    let last_setting_button = this.lastAction()
     $.ajax({
      url: '/api/v1/agent_call_logs/user_call_settings',
      dataType: 'json',
      method: 'post',
      data: {lastAction: last_setting_button},
      success: function (data) {
        self.inDnd(data.is_dnd_active);
        self.inTransfercalls(data.is_transfer_active);
        self.inFollowme(data.is_follow_active);
        self.inAcd(data.is_acd_active);
      }
    });
  }
  this.onCallSettings()

  this.fetchCompanyAgents = function() {
    $.ajax({
      url: '/tasks/get_all_agents',
      dataType: 'json',
      success: function (data) {
        if (data.length === 0) {
          // self.viewModels.messageCounters.moreReady(false);
        }
        else {
          self.companyAgents.destroyAll()
          _.forEach(data, function (agent) {
            self.companyAgents.push(agent);
          });
        }
      }
    });
  }

  this.fetchCallLogs = function() {
    $.ajax({
      url: '/api/v1/agent_call_logs',
      dataType: 'json',
      success: function (data) {
        if (data.length === 0) {
          self.callLogs({});
        }
        else {
          self.setCallLogsFromApi(data);
      }
    }
    });
  }


  this.setCallLogsFromApi = function(data){
    let hashData = {}
    _.forEach(data, function (call) {
      let log       = {...call};
      log['id']     = call.sip_id;
      log['status'] = call.call_status;
      log['stop']   = call.call_stop;
      log['start']  = call.call_start;

      hashData[call.sip_id] = log;
    });

    self.callLogs(hashData);
  }

  this.fetchCallLogs()

  this.subscribe_to_in_call_status = function(){
    $.ajax({
      url: '/tasks/subscribe_to_agents_in_call_status',
      method: 'put',
      success: function (res) {
        _.forEach(res, function(subscription) {
          Danthes.sign(_.extend(subscription, {
            callback: function (data) {
              window.userDashboardApp.viewModels.sipClientViewModel.fetchCompanyAgents()
            },
            connect: true
          }));
        });
      }
    })
  }


  this.deleteAllLogs = function(){
    $.ajax({
      url: '/api/v1/agent_call_logs/destroy_all',
      dataType: 'json',
      method: 'post',
      success: function (data) {
        // if (data.length === 0) {
        //   self.callLogs({});
        // }
        // else {
        //   self.setCallLogsFromApi(data);
      }
    });
  }

  this.danthes_subscribe_call_logs = function(){
    $.ajax({
      url: '/api/v1/agent_call_logs/danthes_subscribe',
      method: 'get',
      success: function (subscription) {
          Danthes.sign(_.extend(subscription, {
            callback: function (data) {
              self.setCallLogsFromApi(data)
              window.ctxSip.logShow();
            },
            connect: true
          }));
      }
    })
  }

  this.danthes_subscribe_call_logs();

  this.save_call_log_in_app = function(calllog, cb){
    $.ajax({
      url: '/api/v1/agent_call_logs',
      method: 'post',
      data: calllog,
      success: function (res) {
        cb(res)
      }
    })
  }



  this.change_in_call_status = (status=false, phone='') => {
    $.ajax({
      url: '/tasks/change_in_call_status',
      method: 'put',
      data: { in_call: status }
    })

    if (status == true && phone && phone.length > 5)
    {
      $.ajax({
        url: '/customers/search_by_phone',
        method: 'post',
        data: {phone},
        success: function (data) {
          if (data && data.customer)
          {
            self.customerFromCall(data.customer)
          }
        }
      })
    }
    else{
      self.customerFromCall({})
    }

  }

  this.showPhoneCustomer = () => {
    window.userDashboardApp.viewModels.customerModal.clearVariables();
    window.userDashboardApp.viewModels.customerModal.loadCustomerById(self.customerId());
    $("#company_modal").modal('toggle'); // Open modal
  }


  this.createTaskWithRecording = () => {
    function setBlobs()
    {
      $(".fileupload-section .attach-file-btn").click()
      let fileInputElement = document.querySelector(".fileupload-section .fileupload.attachments:last-child input.file-field")
      let container = new DataTransfer();
      let file = new File([window.lastCallRecordingBlob], "contakti-recording.amr", { type:"audio/AMR", lastModified:new Date().getTime()});
      container.items.add(file);
      fileInputElement.files = container.files;
      $(fileInputElement).change();
    }
    if (window.last_call_campaign_id) $("#task_campaign_item_id").val(window.last_call_campaign_id)
    window.last_call_campaign_id = null;
    if (window.lastCallRecordingBlob) setBlobs();
    if (window.callDetailsData)
    {
      CKEDITOR.instances['task_messages_attributes_0_description'].setData(window.callDetailsData);
    }
    window.callDetailsData = null;
    $("[data-target='#new_task_modal']").click();
  }


  // this.activeClient = null;

  // this.createCallLogEntry = function() {
  //   var entry = self.clients()[self.activeClient].lastCallDetails;
  //   console.log("===CallEntry===========",entry);
  //   self.companyAgents.unshift(entry);
  //   $.ajax({
  //     url: 'tasks/add_call_history',
  //     method: 'POST',
  //     data: entry,
  //     success: function(entry) {
  //       if(callback) {
  //         callback(entry);
  //       }
  //     },
  //     error: function(a,b,c) {
  //       alert(a);
  //     }
  //   });
  // };


  // this.audioVolume.subscribe(function() {
  //   $('#sip-client-remote-audio')[0].volume = self.audioVolume();
  // });

  // this.acceptCall = function() {
  //   console.log("----------accept call-------------");
  //   _.forEach(self.clients(), function(client, index) {
  //     if(client.incoming) {
  //       client.answer();
  //       self.activeClient = index;
  //       return false;
  //     }
  //   });
  //   self.slidePhone('open');
  // };

  this.slidePhone = function(newState) {
    var element = $('#sip_client_main');
    var element_toggle = $('#sip_client_toggle');
    if(newState === 'open' && !element.is(':visible')) {
      element.toggle('slide', { direction: 'right'}, 400);
      self.phoneHidden(false);
    }
    else if (newState === 'close' && element.is(':visible')) {
      element.toggle('slide', { direction: 'right'}, 400);
      !$(element_toggle).hasClass("d-none") ? $(element_toggle).addClass("d-none") : "";
      self.phoneHidden(true);
    } else if (typeof newState === 'undefined'){
      element.toggle('slide', { direction: 'right'}, 400);
    }

  };

  //$('.phone-slide').on('click', function() {
  //  alert("click");
  //});

  // TODO: handle multiple sip accounts. Now binds only first one.

  this.subscribe_to_in_call_status()
  this.fetchCompanyAgents();
  this.phoneHidden = ko.observable(true);



  window.sip_client = new SipClient(UserDashboard.sipSettings, {
    change_in_call_status: this.change_in_call_status,
    save_call_log_in_app: this.save_call_log_in_app,
    call_logs: this.callLogs,
    deleteAllLogs: this.deleteAllLogs
  });
  // client.initialise();
  // self.clients.push(client);

};

Views.SipClientViewModel.prototype = Views;
