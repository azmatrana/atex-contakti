
function CustomerDecorator(customerJsonModel) {
  var self = this;

  this.id = customerJsonModel.id;
  this.firstName = customerJsonModel.first_name;
  this.lastName = customerJsonModel.last_name;
  this.email = customerJsonModel.email;
  this.phone = customerJsonModel.phone;
  this.city = customerJsonModel.city;
  this.streetAddress = customerJsonModel.street_address;
  this.secondStreetAddress = customerJsonModel.street_address_second;
  this.workTitle = customerJsonModel.work_title;
  this.zipCode = customerJsonModel.zip_code;
  this.fullName = (function() {
    return self.firstName + " " + self.lastName;
  })();
  this.companyId = ko.observable(customerJsonModel.customer_company_id);
  this.companyName = ko.observable();

  if (customerJsonModel.customer_company) {
    this.companyName(customerJsonModel.customer_company.name);
  }
}
