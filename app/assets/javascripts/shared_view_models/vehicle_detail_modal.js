SharedViews.VehicleDetailModal = function() {
    var self = this;
    this.isAdFinlandCompany = ko.observable($("#is_ad_finland_company").val() == "true")
    this.vehicleDetails = ko.observable(null);
    this.vehicleNumber = ko.observable("");
    this.detailsModalSpinner = null;
    this.startLoading = function(){
      self.detailsModalSpinner = new Spinner(_.extend(UserDashboardOptions.spinnerOpts, {
        radius: 10,
        length: 15,
        lines: 12,
        width: 4
      })).spin($('#vehicles_data_table_wrapper')[0]);
    }

    this.stopLoading = function(){
      self.detailsModalSpinner.stop();
    }

    this.vehicleDataTable = ko.computed(function() {
      if(self.vehicleDetails() && self.vehicleDetails().errors.length > 0){
        return I18n.translate("user_dashboard.vehicles_data.no_data")
      }
      else{
        return buildTable(self.vehicleDetails())
      }
    });

    this.vehicleDataTable.subscribe(function (newValue){
      $("#vehicles_data_table").html(newValue);
    })

    this.getVehicleDetails = function (vehicle_number) {
      if (this.isAdFinlandCompany() == true ) {
        this.showVehicleDetailsModal();
        if ( this.vehicleNumber() === vehicle_number ){
          self.stopLoading()
          return;
        }
        else{
          $("#vehicles_data_table").html('');
        }

        this.vehicleNumber(vehicle_number);
        this.startLoading();
        $.ajax({
          url: `chat/get_vehicle_data?reg_num=${vehicle_number}`,
          method: 'GET',
          dataType: 'json',
          success: function (data) {
            self.vehicleDetails(data);
            self.stopLoading();
          }
        });
      }
    }

    this.showVehicleDetailsModal = function(){
      $("#vehicles_data_modal").modal();
    }

};

SharedViews.VehicleDetailModal.prototype = SharedViews;
