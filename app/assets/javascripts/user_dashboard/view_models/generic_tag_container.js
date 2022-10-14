Views.GenericTagItem = function(generic_tag) {
  var self = this;
  this.generic_tag = generic_tag;

  this.deleteClicked = function() {
    self.generic_tag().destroy();
    return true;
  };

};

Views.GenericTagItem.prototype = Views;


