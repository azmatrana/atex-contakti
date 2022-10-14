UserDashboardApp.Danthes = function () {

  var self = this;

  this.initialise = function () {
    data = {};
    $.ajax({
      url: '/tasks/danthes_bulk/bulk_subscribe',
      dataType: 'json',
      data: data,
      success: function (res) {
        _.forEach(res, function(subscription) {
          Danthes.sign(_.extend(subscription['sub'], {
            callback: function (data) {
              console.log('danthes', data);
              if(UserDashboard.current_user_service_channels.find(x => x.id === data.task.service_channel_id) != undefined || UserDashboard.currentUserId === data.task.assigned_to_user_id){
                window.userDashboardApp.viewModels.customerModal.refreshTasks(data);
                userDashboardService[subscription['item']](data);
              }else if(UserDashboard.currentUserId != data.task.assigned_to_user_id){
                window.userDashboardApp.viewModels.customerModal.refreshTasks(data);
                userDashboardService[subscription['item']](data);
              }
            },
            connect: true
          }));
        });
      }
    });
    // _.each(window.UserDashboard.mediaChannels, function (channel) {
    //   _.forEach(['addNewMessage', 'alertWaitingTaskTimeout'], function (item) {
    //     var data;
    //     if (item == 'alertWaitingTaskTimeout') {
    //       data = {sub_channel: item};
    //     } else {
    //       data = {};
    //     }

    //     $.ajax({
    //       url: '/tasks/danthes/' + channel.id,
    //       dataType: 'json',
    //       data: data,
    //       success: function (sub) {
    //         Danthes.sign(_.extend(sub, {
    //           callback: function (data) {
    //             console.log('danthes', data);
    //             if(UserDashboard.current_user_service_channels.find(x => x.id === data.task.service_channel_id) != undefined || UserDashboard.currentUserId === data.task.assigned_to_user_id){
    //               window.userDashboardApp.viewModels.customerModal.refreshTasks(data);
    //               userDashboardService[item](data);
    //             }else if(UserDashboard.currentUserId != data.task.assigned_to_user_id){
    //               window.userDashboardApp.viewModels.customerModal.refreshTasks(data);
    //               userDashboardService[item](data);
    //             }
    //           },
    //           connect: true
    //         }));
    //       }
    //     });
    //   });
    // });
  };


};
