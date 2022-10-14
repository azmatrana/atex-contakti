
function CompanyDecorator(companyJsonModel) {
  var self = this;

  this.id = companyJsonModel.id;
  this.name = companyJsonModel.name;
  this.email = companyJsonModel.email;
  this.city = companyJsonModel.city;
  this.phone = companyJsonModel.phone;
  this.streetAddress = companyJsonModel.street_address;
  this.zipCode = companyJsonModel.zip_code;
  this.businessCode = companyJsonModel.code;

  this.contactPersonId = ko.observable(companyJsonModel.contact_person_id);
  this.contactPersonFirstName = ko.observable();
  this.contactPersonLastName = ko.observable();
  this.contactPersonEmail = ko.observable();


  if (companyJsonModel.contact_person) { //
    this.contactPersonFirstName(companyJsonModel.contact_person.first_name);
    this.contactPersonLastName(companyJsonModel.contact_person.last_name);
    this.contactPersonEmail(companyJsonModel.contact_person.email);
  }
}
