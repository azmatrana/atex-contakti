SharedViews.ProductsViewModel = function() {
  var self = this;
  this.companyVats = ko.observableArray( [] );
  this.vat_percentage = ko.observable( 0.0 );
  this.productWithVat = ko.observable( false );
  this.productTitle = ko.observable("");
  this.productCurrency = ko.observable("");
  this.productPrice = ko.observable(0.0);
  this.productVat = ko.observable(null);
  this.productsList = ko.observableArray([]);
  this.productImages = ko.observableArray([]);
  this.productFiles = ko.observableArray([]);
 this.productDescription = ko.observable("");
 this.disable_controlls = ko.observable(false);
 this.loading = ko.observable(false);
  this.setTimeOut = {};
  this.loading.subscribe( function ( value){
    if (value === true){
      document.getElementById("loader").style.display = "block";
    }
    else{
      document.getElementById("loader").style.display = "none";
    }
  })
  this.selectedVat = ko.observable(null);
  this.productsFilter = ko.observable('');
  this.selectedProduct = ko.observable({})
  this.selectedProductImages = ko.observableArray([]);
  this.selectedProductFiles = ko.observableArray([]);

  this.filteredProductsList = ko.computed(function () {
    return self.productsList().filter(function (obj) {
      return (obj.title.toLocaleLowerCase().includes(self.productsFilter().toLocaleLowerCase()));
    });
  })

  this.showStatus = function (text, htmlSelector) {
    $(htmlSelector).addClass("hide")
    clearTimeout(self.setTimeOut[htmlSelector]);
    if (text) {
      $(htmlSelector).removeClass("hide");
      $(htmlSelector).text(text);
      self.setTimeOut[htmlSelector] = setTimeout(function () {
        $(htmlSelector).addClass("hide")
      }, 5000);
    }
  };
  this.createProduct = function(){
   const FILES = $("#product_files_input")[0].files
    const IMAGES = $("#product_images_input")[0].files

    var data = new FormData();
    $.each(FILES, function (i, file) {
      data.append(`product[attachments_attributes][][file]`, file);
    });

    $.each(IMAGES , function (i, image) {
      data.append(`product[images_attributes][][file]`, image);
    });

    data.append( "product[title]", self.productTitle() );
    data.append( "product[price]", self.productPrice() );
    data.append("product[with_vat]", self.productWithVat());
    data.append("product[vat_id]", self.productVat() || '');
    data.append( "product[description]", self.productDescription() );
    self.disable_controlls(true);

    $.ajax({
      url: '/' + I18n.locale + '/chatbot/products',
      type: 'POST',
      // cache: false,
      contentType: false,
      processData: false,
      data: data,
      success: function (response) {
        self.disable_controlls(false);
        if (response.errors) {
          self.showStatus(response.errors, "#product_error")
        } else {
          self.productsList.push(response.data);
          self.showStatus(response.success, "#product_success")
          self.productTitle('');
          self.productWithVat(false);
          self.productDescription('');
          self.productPrice(0.0);
          self.productVat(null);
          self.productImages([]);
          self.productFiles([]);
        }
      }
    })
  };

  this.createVat = function () {
    self.disable_controlls(true);

		var data = new FormData();
		data.append("vat[vat_percentage]", self.vat_percentage());

		$.ajax({
			url: "/" + I18n.locale + "/vats",
			type: "POST",
			// cache: false,
			contentType: false,
			processData: false,
			data: data,
			success: function (response) {
				self.disable_controlls(false);
				if (response.errors) {
					self.showStatus(response.errors, "#vat_error");
				} else {
          self.showStatus(response.success, "#vat_success");
          self.getCompanyVatsAndCurrency();
					self.vat_percentage(0.0);
				}
			},
    });
  };
  
  this.updateVat = function (data) {
    self.disable_controlls( true );
    
    let dataToUpdate = new FormData();
    dataToUpdate.append( "vat[vat_percentage]", data.vat_percentage )
    
		$.ajax({
			url: "/" + I18n.locale + "/vats/" + data.id,
			type: "PUT",
			// cache: false,
			contentType: false,
			processData: false,
			data: dataToUpdate,
			success: function (response) {
				self.disable_controlls(false);
				if (response.errors) {
					self.showStatus(response.errors, "#vat_error");
				} else {
					self.showStatus(response.success, "#vat_success");
					self.getCompanyVatsAndCurrency();
					self.vat_percentage(0.0);
				}
			},
		});
  };
  
  this.deleteVat = function (id) {
		self.disable_controlls(true);

		$.ajax({
			url: "/" + I18n.locale + "/vats/" + id,
			method: "DELETE",
			success: function (response) {
				self.disable_controlls(false);
				if (response.errors) {
					self.showStatus(response.errors, "#vat_error");
				} else {
					self.showStatus(response.success, "#vat_success");
					self.getCompanyVatsAndCurrency();
					self.vat_percentage(0.0);
				}
			},
		});
	};

  this.getCompanyVatsAndCurrency = function () {
    $.ajax({
			url: "/chatbot/products/get_company_vats_and_currency",
			dataType: "json",
			success: function (data) {
        self.companyVats(data.vats)
				self.productCurrency(data.currency);
			},
		});
  }

  self.getCompanyVatsAndCurrency();

  this.fetchProductsList = function () {
    $.ajax({
      url: '/chatbot/products',
      dataType: 'json',
      success: function (data) {
        self.productsList.destroyAll()
        data.forEach(function (product) {
          self.productsList.push(product);
        });
      }
    });
  }
  this.fetchProductsList();

  this.deleteProduct = function(){
    if(this.answers_count > 0){
      let changed = confirm(window.I18n.translations[window.I18n.locale].user_dashboard.answers_associated + ":" + this.answers_count + "\n"
        + window.I18n.translations[window.I18n.locale].user_dashboard.confirm_delete
      )
      if (changed == false)
      {
        return
      }
    }
    $.ajax({
      url: '/' + I18n.locale + "/chatbot/products/" + this.id,
      method: 'DELETE',
      success: function (resp) {
        self.showStatus(resp.success, "#product_success")
        self.fetchProductsList();
      },
      error: function (resp) {
        self.showStatus(resp.errors, "#product_error")
      }
    });
  }

  this.showEditProductModal = function() {
    self.selectedProduct({});
    self.selectedVat(null)

    self.disable_controlls(true)
    self.loading(true);
    $.ajax({
      url: '/' + I18n.locale + "/chatbot/products/" + this.id,
      method: 'GET',
      success: function (resp) {
        self.selectedProduct(resp.data);
        self.productWithVat(resp.data.with_vat);
        self.selectedVat(resp.data.vat?.id || null);
        self.disable_controlls(false)
        self.loading(false);
      }
    });

    $(`span.images_item_cell`).removeClass("hide");
    $(`span.product_file`).removeClass("hide");
    $('#products_edit_modal').modal();
  }

  this.removeImage = function(){
    this["_destroy"] = true;
    $(`#product_image_${this.id}`).addClass("hide");
  }
  this.removeFile = function(){
    this["_destroy"] = true;
    $(`#product_file_${this.id}`).addClass("hide");
  }

  this.editProduct = function(){
    const FILES = $(`#product_edit_files_input${self.selectedProduct().id}`)[0].files
    const IMAGES = $(`#product_edit_images_input${self.selectedProduct().id}`)[0].files

    var data = new FormData();
    $.each(FILES, function (i, file) {
      data.append(`product[attachments_attributes][][file]`, file);
      data.append(`product[attachments_attributes][][id]`, '');
      data.append(`product[attachments_attributes][][_destroy]`, false);
    });

    $.each(IMAGES , function (i, image) {
      data.append(`product[images_attributes][][file]`, image);
      data.append(`product[images_attributes][][id]`, '');
      data.append(`product[images_attributes][][_destroy]`, false);
    });

    data.append( "product[id]", self.selectedProduct().id)
    data.append( "product[title]", self.selectedProduct().title)
    data.append( "product[description]", self.selectedProduct().description )
    data.append( "product[price]", self.selectedProduct().price)
    data.append( "product[with_vat]", self.productWithVat() );
    data.append("product[vat_id]", ( self.selectedVat() || ''));

    self.selectedProduct().images.forEach((image, i) => {
      data.append(`product[images_attributes][][id]`, image.id);
      data.append(`product[images_attributes][][_destroy]`, image._destroy ? true : false);
    });

    self.selectedProduct().attachments.forEach((file, i) => {
      data.append(`product[attachments_attributes][][id]`, file.id);
      data.append(`product[attachments_attributes][][_destroy]`, file._destroy ? true : false);
    });

    self.disable_controlls(true);
    $.ajax({
      url: '/' + I18n.locale + '/chatbot/products/' + self.selectedProduct().id,
      contentType: false,
      processData: false,
      method: 'PATCH',
      data: data,
      success: function (response) {
        self.disable_controlls(false);
        if (response.errors) {
          self.showStatus(response.errors, "#product_edit_error")
        } else {
          self.showStatus(response.success, "#product_edit_success");
          var index = self.productsList().findIndex(obj =>  obj.id === response.data.id);
          self.productsList.splice(index, 1, response.data);
          self.selectedProduct(response.data);
          self.productWithVat( response.data.with_vat);
          self.selectedVat(response.data.vat?.id || null);
          self.selectedProductImages([]);
          self.selectedProductFiles([]);
        }
      }
    })
  }

  this.closeModal = function(){
    $("#products_edit_modal").modal("hide");
  }

  $(document).on('click', '[data-toggle="lightbox"]', function(event) {
                event.preventDefault();
            });

}
SharedViews.ProductsViewModel.prototype = SharedViews;
