//= require ./shared_view_models/base

function ManagerAppViews() {
  this.viewModels = {
    companyFiles: new SharedViews.CompanyFileViewModel(),
    chatTemplates: new SharedViews.ReplyTemplates(),
    basicTemplates: new SharedViews.BasicTemplates(),
    productsModel: new SharedViews.ProductsViewModel(),
    shipmentMethod: new SharedViews.ShipmentMethod(),
    cartEmailTemplates: new SharedViews.CartEmailTemplates(),
    thirdPartyTools: new SharedViews.ThirdPartyTools(),
  }
  window.managerAppViews = this.viewModels;
}

$(document).ready(function (){
  ko.applyBindings( new ManagerAppViews())
})
