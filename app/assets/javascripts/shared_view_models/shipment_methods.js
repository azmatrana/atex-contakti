SharedViews.ShipmentMethod = function() {
    var self = this;
    this.shipmentMethodName = ko.observable("");
    this.shipmentMethodPrice = ko.observable(0.0);
    this.shipmentMethodsList = ko.observableArray([]);
    this.disable_controlls = ko.observable(false);
    this.setTimeOut = {};
    this.shipmentMethodsFilter = ko.observable('');

    this.filteredShipmentMethodsList = ko.computed(function () {
      return self.shipmentMethodsList().filter(function (obj) {
        return (obj.name.toLocaleLowerCase().includes(self.shipmentMethodsFilter().toLocaleLowerCase()));
      });
    })

    this.showStatus = function (msg, htmlSelector) {
      $(htmlSelector).addClass("hide")
      clearTimeout(self.setTimeOut[htmlSelector]);
      if (msg) {
        $(htmlSelector).removeClass("hide");
        $(htmlSelector).text(msg);
        self.setTimeOut[htmlSelector] = setTimeout(function () {
          $(htmlSelector).addClass("hide")
        }, 5000);
      }
    };

    this.createShipmentMethod = function(){
      var data = new FormData();
      data.append( "shipment_method[name]", self.shipmentMethodName() );
      data.append("shipment_method[price]", self.shipmentMethodPrice());

      this.disable_controlls(true);

      $.ajax({
        url: '/' + I18n.locale + '/shipment_methods',
        type: 'POST',
        // cache: false,
        contentType: false,
        processData: false,
        data: data,
        success: function (response) {
          self.disable_controlls(false);
          if (response.errors) {
            self.showStatus(response.errors, "#shipment_method_error")
          } else {
            self.showStatus(response.success, "#shipment_method_success")
            self.fetchShipmentMethodsList();
            self.shipmentMethodName('');
          }
        }
      })
    };

     this.fetchShipmentMethodsList = function () {
      $.ajax({
        url: '/' + I18n.locale + '/shipment_methods',
        dataType: 'json',
        success: function (data) {
          self.shipmentMethodsList.destroyAll()
          data.forEach( function ( shipmentMethod ) {
            shipmentMethod.price = displayPrice( shipmentMethod.price );
            self.shipmentMethodsList.push(shipmentMethod);
          });
        }
      });
    }
  this.fetchShipmentMethodsList();



  this.updateShipmentMethod = function (data) {
		self.disable_controlls(true);

		let dataToUpdate = new FormData();
      dataToUpdate.append("shipment_method[price]", data.price);
		$.ajax({
			url: "/" + I18n.locale + "/shipment_methods/" + data.id,
			type: "PUT",
			// cache: false,
			contentType: false,
			processData: false,
			data: dataToUpdate,
			success: function (response) {
          self.disable_controlls(false);
          if (response.errors) {
            self.showStatus(response.errors, "#shipment_method_error")
          } else {
            self.fetchShipmentMethodsList();
            self.showStatus(response.success, "#shipment_method_success")
          }
        }
		});
	};

    this.deleteShipmentMethod = function (id) {
      let changed = confirm(window.I18n.translations[window.I18n.locale].user_dashboard.confirm_delete)
      if (changed == false) {
        return;
      }
      $.ajax({
        url: '/' + I18n.locale + "/shipment_methods/" + id,
        method: 'DELETE',
        success: function (resp) {
          self.showStatus(resp.success, "#shipment_method_success")
          self.fetchShipmentMethodsList();
        },
        error: function (resp) {
          self.showStatus(resp.errors, "#shipment_method_error")
        }
      });
    }
  }
  SharedViews.ShipmentMethod.prototype = SharedViews;
