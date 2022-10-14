SharedViews.CartEmailTemplates = function() {
  var self = this;

  this.templateName = ko.observable("");
  this.templateSubject = ko.observable("");

	this.orderPaymentLinkTemplateName = ko.observable("");
	this.orderPaymentLinkTemplateSubject = ko.observable("");

  this.termsAndConditionsName = ko.observable( "" );
  this.termsAndConditionsHeading = ko.observable( "" );

  this.disable_controlls = ko.observable(false);
  this.setTimeOut = {};

  $(document).ready(function () {

    self.orderPlacedEditor = CKEDITOR.replace("order_placed_template_body", {
  		language: I18n.currentLocale(),
  		removePlugins: "elementspath",
  		resize_enabled: false,
  		removePlugins: 'autogrow'
  	});

    self.paymentLinkEditor = CKEDITOR.replace("order_payment_link_template_body", {
    	language: I18n.currentLocale(),
    	removePlugins: "elementspath",
    	resize_enabled: false,
  		removePlugins: 'autogrow'
    });

    self.termsAndConditionsEditor = CKEDITOR.replace("order_terms_and_conditions_template_body", {
    	language: I18n.currentLocale(),
    	removePlugins: "elementspath",
    	resize_enabled: false,
  		removePlugins: 'autogrow'
    });

    setTimeout(function(){
      self.getOrderPlacedTemplate();
      self.getOrderPaymentLinkTemplate();
      self.getOrderTermsAndConditionsTemplate();
    }, 1000)

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

  this.createOrderPlacedTemplate = function () {
		var data = new FormData();
    data.append("cart_email_template[name]", self.templateName());
    data.append("cart_email_template[subject]", self.templateSubject());
    data.append("cart_email_template[body]", self.orderPlacedEditor.getData());
		this.disable_controlls(true);

		$.ajax({
			url: "/" + I18n.locale + "/cart_email_templates/create_update_order_placed_template",
			type: "POST",
			// cache: false,
			contentType: false,
			processData: false,
			data: data,
			success: function (response) {
        self.disable_controlls( false );
				if (response.errors) {
					self.showStatus(response.errors, "#cart_email_templates_error");
				} else {
					self.showStatus(response.success, "#cart_email_templates_success");
				}
			},
		});
	};

  this.getOrderPlacedTemplate = function () {
    $.ajax({
      url: '/' + I18n.locale + '/cart_email_templates/get_order_placed_template',
      dataType: 'json',
      success: function (data) {
        self.templateName(data && data.name);
        self.templateSubject(data && data.subject);
        // self.templateBody(data && data.body);
        // $("#order_placed_template_body").val(data && data.body);
        self.orderPlacedEditor.setData( ( data && data.body ) || "" );
      }
    });
  }



  this.createPaymentLinkTemplate = function () {
    var data = new FormData();
    data.append("cart_email_template[name]", self.orderPaymentLinkTemplateName());
    data.append("cart_email_template[subject]", self.orderPaymentLinkTemplateSubject());
    data.append("cart_email_template[body]", self.paymentLinkEditor.getData());
		this.disable_controlls(true);

		$.ajax({
			url: "/" + I18n.locale + "/cart_email_templates/create_update_payment_link_template",
			type: "POST",
			// cache: false,
			contentType: false,
			processData: false,
			data: data,
			success: function (response) {
        self.disable_controlls( false );
				if (response.errors) {
					self.showStatus(response.errors, "#payment_link_error");
				} else {
					self.showStatus(response.success, "#payment_link_success");
				}
			},
		});
  }

  this.getOrderPaymentLinkTemplate = function () {
		$.ajax({
			url: "/" + I18n.locale + "/cart_email_templates/get_order_payment_link_template",
			dataType: "json",
			success: function (data) {
				self.orderPaymentLinkTemplateName(data && data.name);
				self.orderPaymentLinkTemplateSubject(data && data.subject);
        // self.orderPaymentLinkTemplateBody( data && data.body );
        self.paymentLinkEditor.setData((data && data.body) || "ss");
        // $("#order_payment_link_template_body").val(data && data.body);
			},
		});
	};



  this.createTermsAndConditionsTemplate = function () {
		var data = new FormData();
    data.append("cart_email_template[name]", self.termsAndConditionsName());
    data.append("cart_email_template[subject]", self.termsAndConditionsHeading());
    data.append("cart_email_template[body]", self.termsAndConditionsEditor.getData());
		this.disable_controlls(true);

		$.ajax({
			url: "/" + I18n.locale + "/cart_email_templates/create_update_terms_and_conditions_template",
			type: "POST",
			// cache: false,
			contentType: false,
			processData: false,
			data: data,
			success: function (response) {
        self.disable_controlls( false );
				if (response.errors) {
					self.showStatus(response.errors, "#terms_and_conditions_error");
				} else {
					self.showStatus(response.success, "#terms_and_conditions_success");
				}
			},
		});
	};

  this.getOrderTermsAndConditionsTemplate = function () {
    $.ajax({
      url: '/' + I18n.locale + '/cart_email_templates/get_order_terms_and_conditions_template',
      dataType: 'json',
      success: function (data) {
        self.termsAndConditionsName(data?.name);
        self.termsAndConditionsHeading(data?.subject);
        self.termsAndConditionsEditor.setData( ( data?.body ) || "" );
      }
    });
  }



}
SharedViews.CartEmailTemplates.prototype = SharedViews;
